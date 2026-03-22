#Requires -Version 5.1

<#
.SYNOPSIS
    Builds the MSIX package and creates a draft GitHub Release for DhikrAtWork (Windows).
.DESCRIPTION
    Two-step release process — this is step 1 (Windows). Step 2 is release.sh on macOS.

    The script:
      1. Validates prerequisites — auto-generates the signing certificate if missing
      2. Pulls latest main and aborts if the working tree is dirty
      3. Bumps version in pubspec.yaml (version + msix_version) and pushes to main
      4. Runs flutter build windows --release
      5. Runs flutter pub run msix:create with the certificate password
      6. Creates a distribution zip with README.txt, Install.bat, .cer, and .msix
      7. Computes SHA256 checksums for both the MSIX and the zip
      8. Creates a draft GitHub Release with the changelog as body
      9. Uploads the zip, its checksum, and the bare MSIX to the draft release

    If the signing certificate does not exist, it is generated automatically.
    The certificate password is read from $env:MSIX_CERT_PASSWORD if set,
    otherwise the script prompts for it interactively.

    Prerequisites:
      - gh CLI must be installed and authenticated (gh auth status)
.PARAMETER Version
    The release version, e.g. '0.2.0'. Must be in X.Y.Z semver format.
.PARAMETER Changelog
    The changelog text for this release. Multi-line strings are supported.
    This text is stored as the GitHub Release body so release.sh can read it.
.EXAMPLE
    .\release.ps1 -Version 0.2.0 -Changelog "Added statistics screen, fixed hotkey bug"
.EXAMPLE
    # Pre-set password to skip the interactive prompt:
    $env:MSIX_CERT_PASSWORD = "your-password"
    .\release.ps1 -Version 0.2.0 -Changelog "Added statistics screen"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Changelog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------
$ProjectRoot    = $PSScriptRoot
$PfxPath        = Join-Path $ProjectRoot 'windows\signing\CERTIFICATE.pfx'
$CerPath        = Join-Path $ProjectRoot 'DhikrAtWork.cer'
$PubspecPath    = Join-Path $ProjectRoot 'pubspec.yaml'
$InstallBatPath = Join-Path $ProjectRoot 'Install.bat'
$ReadmeTemplate = Join-Path $ProjectRoot 'dist\README-windows.txt'
$MsixBuildPath  = Join-Path $ProjectRoot 'build\windows\x64\runner\Release\DhikrAtWork.msix'

$ZipName        = "DhikrAtWork-v${Version}-windows-x64"
$ZipFileName    = "${ZipName}.zip"
$ChecksumFile   = "${ZipFileName}.sha256"

$StagingDir     = Join-Path $ProjectRoot "build\_release_staging\${ZipName}"
$ZipOutputPath  = Join-Path $ProjectRoot "build\_release_staging\${ZipFileName}"
$ChecksumPath   = Join-Path $ProjectRoot "build\_release_staging\${ChecksumFile}"

# ---------------------------------------------------------------------------
# Helpers — matching build.ps1 style
# ---------------------------------------------------------------------------
function Write-StepHeader {
    param([string]$Step, [string]$Description)
    Write-Host ''
    Write-Host "[$Step] $Description" -ForegroundColor Cyan
    Write-Host ('-' * 60) -ForegroundColor DarkGray
}

function Write-Pass {
    param([string]$Message)
    Write-Host "  PASS  $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  FAIL  $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  INFO  $Message" -ForegroundColor DarkGray
}

function Invoke-Command-Checked {
    <#
    .SYNOPSIS
        Runs an external command, streams output in real time, and throws on non-zero exit.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Executable,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [string]$WorkingDirectory = $ProjectRoot
    )

    # Resolve full path so .bat/.cmd files (e.g. flutter.bat) work with Process.Start
    $resolvedExe = (Get-Command $Executable -ErrorAction Stop).Source

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName               = $resolvedExe
    $psi.Arguments              = $Arguments -join ' '
    $psi.WorkingDirectory       = $WorkingDirectory
    $psi.UseShellExecute        = $false

    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit() | Out-Null

    if ($process.ExitCode -ne 0) {
        throw "$Executable $($Arguments -join ' ') exited with code $($process.ExitCode)"
    }
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '========================================' -ForegroundColor Yellow
Write-Host '  DhikrAtWork Release Pipeline (Windows)' -ForegroundColor Yellow
Write-Host "  Version: v${Version}" -ForegroundColor Yellow
Write-Host '========================================' -ForegroundColor Yellow

$timer = [System.Diagnostics.Stopwatch]::StartNew()
$CertGenerated = $false

# ---------------------------------------------------------------------------
# Step 1: Validate prerequisites
# ---------------------------------------------------------------------------
Write-StepHeader -Step '1/9' -Description 'Validating prerequisites'

# --- Certificate handling: auto-generate if missing ---
if (-not (Test-Path $PfxPath)) {
    Write-Info "No signing certificate found — generating one now..."
    Write-Host ''

    # Ensure signing directory exists
    $signingDir = Split-Path $PfxPath -Parent
    if (-not (Test-Path $signingDir)) {
        New-Item -ItemType Directory -Path $signingDir -Force | Out-Null
    }

    # Get password: use env var if already set, otherwise prompt interactively
    if ([string]::IsNullOrEmpty($env:MSIX_CERT_PASSWORD)) {
        Write-Host '  Choose a password for the signing certificate.' -ForegroundColor Yellow
        Write-Host '  Save it — you will need it for future releases.' -ForegroundColor Yellow
        Write-Host ''
        $secPassword = Read-Host -Prompt '  Certificate password' -AsSecureString
        $secConfirm  = Read-Host -Prompt '  Confirm password'     -AsSecureString
        $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPassword))
        $pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secConfirm))
        if ($pwd1 -ne $pwd2) {
            Write-Fail 'Passwords do not match.'
            exit 1
        }
        if ([string]::IsNullOrEmpty($pwd1)) {
            Write-Fail 'Password must not be empty.'
            exit 1
        }
        $env:MSIX_CERT_PASSWORD = $pwd1
    }
    else {
        Write-Info "Using password from MSIX_CERT_PASSWORD env var"
    }

    $secPfxPassword = ConvertTo-SecureString -String $env:MSIX_CERT_PASSWORD -AsPlainText -Force

    Write-Info "Generating self-signed code signing certificate (valid 5 years)..."
    $cert = New-SelfSignedCertificate `
        -Subject 'CN=DhikrAtWork Open Source' `
        -Type CodeSigningCert `
        -KeyUsage DigitalSignature `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -NotAfter (Get-Date).AddYears(5) `
        -HashAlgorithm SHA256

    Export-Certificate -Cert $cert -FilePath $CerPath -Type CERT -Force | Out-Null
    Write-Pass "Exported public certificate: DhikrAtWork.cer"

    Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $secPfxPassword -Force | Out-Null
    Write-Pass "Exported private key: windows\signing\CERTIFICATE.pfx"

    Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
    $CertGenerated = $true
    Write-Pass "Certificate generated successfully"
}
else {
    Write-Pass "CERTIFICATE.pfx found"
}

# .cer public certificate (should exist if cert was just generated or from a prior run)
if (-not (Test-Path $CerPath)) {
    Write-Fail "Public certificate not found: $CerPath"
    Write-Host ''
    Write-Host '  The .pfx exists but .cer is missing. Delete windows\signing\CERTIFICATE.pfx' -ForegroundColor Yellow
    Write-Host '  and re-run this script to regenerate both files.' -ForegroundColor Yellow
    exit 1
}
Write-Pass "DhikrAtWork.cer found"

# Certificate password: prompt if not already set (existing cert, no env var)
if ([string]::IsNullOrEmpty($env:MSIX_CERT_PASSWORD)) {
    Write-Info "MSIX_CERT_PASSWORD not set — prompting for certificate password..."
    Write-Host ''
    $secPwd = Read-Host -Prompt '  Certificate password' -AsSecureString
    $plainPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPwd))
    if ([string]::IsNullOrEmpty($plainPwd)) {
        Write-Fail 'Password must not be empty.'
        exit 1
    }
    $env:MSIX_CERT_PASSWORD = $plainPwd
    Write-Pass "Certificate password set for this session"
}
else {
    Write-Pass "MSIX_CERT_PASSWORD is set"
}

# Install.bat
if (-not (Test-Path $InstallBatPath)) {
    Write-Fail "Install.bat not found: $InstallBatPath"
    exit 1
}
Write-Pass "Install.bat found"

# README template
if (-not (Test-Path $ReadmeTemplate)) {
    Write-Fail "README template not found: $ReadmeTemplate"
    exit 1
}
Write-Pass "dist\README-windows.txt found"

# gh CLI availability
try {
    $ghVersion = & gh --version 2>&1 | Select-Object -First 1
    Write-Pass "gh CLI found ($ghVersion)"
}
catch {
    Write-Fail 'gh CLI not found. Install from https://cli.github.com/'
    exit 1
}

# gh authentication
$ghAuthStatus = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'gh CLI is not authenticated. Run: gh auth login'
    exit 1
}
Write-Pass "gh CLI authenticated"

# Check the tag doesn't already exist
$existingRelease = & gh release view "v${Version}" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Fail "GitHub Release v${Version} already exists. Delete it first or use a different version."
    exit 1
}
Write-Pass "Tag v${Version} does not yet exist"

# ---------------------------------------------------------------------------
# Step 2: Git pull and clean working tree check
# ---------------------------------------------------------------------------
Write-StepHeader -Step '2/9' -Description 'Syncing with remote (git pull origin main)'

& git -C $ProjectRoot pull origin main
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'git pull failed. Resolve conflicts and retry.'
    exit 1
}
Write-Pass "Pulled latest main"

$gitStatus = & git -C $ProjectRoot status --porcelain 2>&1
if (-not [string]::IsNullOrWhiteSpace($gitStatus)) {
    if ($CertGenerated) {
        # Filter out the newly generated .cer — it will be committed with the version bump
        $otherChanges = ($gitStatus -split "`n") | Where-Object { $_ -notmatch 'DhikrAtWork\.cer$' }
        if ($otherChanges.Count -gt 0) {
            Write-Fail 'Working tree has uncommitted changes (besides the new certificate).'
            Write-Host ''
            Write-Host ($otherChanges -join "`n") -ForegroundColor Yellow
            exit 1
        }
        Write-Info "Only new DhikrAtWork.cer detected (will be committed with version bump)"
    }
    else {
        Write-Fail 'Working tree has uncommitted changes. Commit or stash them first.'
        Write-Host ''
        Write-Host $gitStatus -ForegroundColor Yellow
        exit 1
    }
}
Write-Pass "Working tree is clean"

# ---------------------------------------------------------------------------
# Step 3: Bump version in pubspec.yaml
# ---------------------------------------------------------------------------
Write-StepHeader -Step '3/9' -Description "Bumping pubspec.yaml to v${Version}"

$pubspecContent = Get-Content $PubspecPath -Raw

# Parse current build number from version line, e.g. "version: 0.1.0+1"
$versionMatch = [regex]::Match($pubspecContent, '(?m)^version:\s*\S+\+(\d+)\s*$')
if ($versionMatch.Success) {
    $currentBuild = [int]$versionMatch.Groups[1].Value
    $newBuild     = $currentBuild + 1
}
else {
    # No +build suffix — start at 1
    $newBuild = 1
}

$newFlutterVersion = "${Version}+${newBuild}"
$newMsixVersion    = "${Version}.0"

Write-Info "Flutter version: $newFlutterVersion"
Write-Info "MSIX version:    $newMsixVersion"

# Replace top-level version: line
$pubspecContent = [regex]::Replace(
    $pubspecContent,
    '(?m)^(version:\s*)\S+(\s*)$',
    "`${1}${newFlutterVersion}`${2}"
)

# Replace or insert msix_version under msix_config:
# Strategy: if the key exists, replace it; if not, insert it after the msix_config: line.
if ($pubspecContent -match '(?m)^(\s+msix_version:\s*)\S+(\s*)$') {
    $pubspecContent = [regex]::Replace(
        $pubspecContent,
        '(?m)^(\s+msix_version:\s*)\S+(\s*)$',
        "`${1}${newMsixVersion}`${2}"
    )
    Write-Info "Updated existing msix_version"
}
else {
    # Insert msix_version: on the line after msix_config:
    $pubspecContent = [regex]::Replace(
        $pubspecContent,
        '(?m)^(msix_config:\s*\r?\n)',
        "`${1}  msix_version: ${newMsixVersion}`n"
    )
    Write-Info "Inserted new msix_version"
}

Set-Content -Path $PubspecPath -Value $pubspecContent -NoNewline -Encoding UTF8
Write-Pass "pubspec.yaml updated"

# Commit and push
& git -C $ProjectRoot add $PubspecPath
if ($LASTEXITCODE -ne 0) { throw 'git add pubspec.yaml failed' }

if ($CertGenerated) {
    & git -C $ProjectRoot add $CerPath
    if ($LASTEXITCODE -ne 0) { throw 'git add DhikrAtWork.cer failed' }
}

$commitMsg = if ($CertGenerated) {
    "chore: bump version to ${Version} and add signing certificate"
} else {
    "chore: bump version to ${Version}"
}

& git -C $ProjectRoot commit -m $commitMsg
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }

& git -C $ProjectRoot push origin main
if ($LASTEXITCODE -ne 0) { throw 'git push failed' }

Write-Pass "Committed and pushed version bump"

# ---------------------------------------------------------------------------
# Step 4: Build Flutter Windows release
# ---------------------------------------------------------------------------
Write-StepHeader -Step '4/9' -Description 'flutter build windows --release'

Invoke-Command-Checked -Executable 'flutter' -Arguments @('build', 'windows', '--release')
Write-Pass "flutter build windows --release succeeded"

# ---------------------------------------------------------------------------
# Step 5: Create MSIX package
# ---------------------------------------------------------------------------
Write-StepHeader -Step '5/9' -Description 'flutter pub run msix:create'

# Certificate password is shell-interpolated — msix:create does not read env vars directly
Invoke-Command-Checked -Executable 'flutter' -Arguments @(
    'pub', 'run', 'msix:create',
    '--certificate-password', $env:MSIX_CERT_PASSWORD
)

if (-not (Test-Path $MsixBuildPath)) {
    Write-Fail "MSIX not found at expected location: $MsixBuildPath"
    exit 1
}

$msixInfo = Get-Item $MsixBuildPath
$msixSizeMB = [math]::Round($msixInfo.Length / 1MB, 2)
Write-Pass "DhikrAtWork.msix created ($msixSizeMB MB)"

# ---------------------------------------------------------------------------
# Step 6: Compute SHA256 of MSIX
# ---------------------------------------------------------------------------
Write-StepHeader -Step '6/9' -Description 'Computing SHA256 checksums'

$msixHash = (Get-FileHash -Path $MsixBuildPath -Algorithm SHA256).Hash
Write-Info "MSIX SHA256: $msixHash"
Write-Pass "MSIX checksum computed"

# ---------------------------------------------------------------------------
# Step 7: Build distribution zip
# ---------------------------------------------------------------------------
Write-StepHeader -Step '7/9' -Description "Building distribution zip: ${ZipFileName}"

# Clean and create staging directory with subfolder
if (Test-Path (Split-Path $StagingDir -Parent)) {
    Remove-Item -Path (Split-Path $StagingDir -Parent) -Recurse -Force
}
New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

# Process README template — replace {{VERSION}} only (no SHA256 in README)
$readmeContent = Get-Content $ReadmeTemplate -Raw
$readmeContent = $readmeContent -replace '\{\{VERSION\}\}', $Version

$readmeStagingPath = Join-Path $StagingDir 'README.txt'
Set-Content -Path $readmeStagingPath -Value $readmeContent -Encoding UTF8

# Copy other files
Copy-Item -Path $InstallBatPath -Destination (Join-Path $StagingDir 'Install.bat')
Copy-Item -Path $CerPath        -Destination (Join-Path $StagingDir 'DhikrAtWork.cer')
Copy-Item -Path $MsixBuildPath  -Destination (Join-Path $StagingDir 'DhikrAtWork.msix')

Write-Info "Staging directory contents:"
Get-ChildItem $StagingDir | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Info "  $($_.Name) ($sizeMB MB)"
}

# Create zip from the staging parent — so the zip contains the DhikrAtWork-vX.Y.Z-windows-x64\ subfolder
Compress-Archive -Path $StagingDir -DestinationPath $ZipOutputPath -Force
Write-Pass "Distribution zip created: $ZipFileName"

# Compute SHA256 of the zip and write checksum file
$zipHash = (Get-FileHash -Path $ZipOutputPath -Algorithm SHA256).Hash
Write-Info "Zip SHA256: $zipHash"

# Write checksum file — two-space convention matching sha256sum output
$checksumLine = "${zipHash}  ${ZipFileName}"
Set-Content -Path $ChecksumPath -Value $checksumLine -Encoding UTF8 -NoNewline
Write-Pass "Checksum file created: ${ChecksumFile}"

$zipInfo    = Get-Item $ZipOutputPath
$zipSizeMB  = [math]::Round($zipInfo.Length / 1MB, 2)
Write-Info "Zip size: $zipSizeMB MB"

# ---------------------------------------------------------------------------
# Step 8: Create draft GitHub Release
# ---------------------------------------------------------------------------
Write-StepHeader -Step '8/9' -Description "Creating draft GitHub Release v${Version}"

# Write changelog to a temp file so --notes-file handles multi-line content safely
$tempNotesFile = [System.IO.Path]::GetTempFileName()
try {
    Set-Content -Path $tempNotesFile -Value $Changelog -Encoding UTF8

    & gh release create "v${Version}" `
        --draft `
        --title "DhikrAtWork v${Version}" `
        --notes-file $tempNotesFile

    if ($LASTEXITCODE -ne 0) {
        throw "gh release create failed with exit code $LASTEXITCODE"
    }
}
finally {
    Remove-Item -Path $tempNotesFile -Force -ErrorAction SilentlyContinue
}

Write-Pass "Draft release v${Version} created on GitHub"

# ---------------------------------------------------------------------------
# Step 9: Upload artifacts to the draft release
# ---------------------------------------------------------------------------
Write-StepHeader -Step '9/9' -Description 'Uploading release artifacts'

& gh release upload "v${Version}" $ZipOutputPath $ChecksumPath $MsixBuildPath
if ($LASTEXITCODE -ne 0) {
    throw "gh release upload failed with exit code $LASTEXITCODE"
}

Write-Pass "Uploaded: $ZipFileName"
Write-Pass "Uploaded: $ChecksumFile"
Write-Pass "Uploaded: DhikrAtWork.msix"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$timer.Stop()
$elapsed = [math]::Round($timer.Elapsed.TotalSeconds, 1)

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host '  Release pipeline complete!' -ForegroundColor Green
Write-Host "  Duration: ${elapsed}s" -ForegroundColor DarkGray
Write-Host '========================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Artifacts created:' -ForegroundColor White
Write-Host "    $ZipFileName" -ForegroundColor DarkGray
Write-Host "    $ChecksumFile" -ForegroundColor DarkGray
Write-Host "    DhikrAtWork.msix  (bare MSIX for .appinstaller auto-update)" -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Draft release:' -ForegroundColor White
Write-Host "    https://github.com/thecodeartificerX/dhikratwork/releases/tag/v${Version}" -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Yellow
Write-Host '    1. Switch to your Mac.' -ForegroundColor White
Write-Host "    2. Run: ./release.sh ${Version}" -ForegroundColor White
Write-Host '       This builds the macOS package, generates appcast.xml,' -ForegroundColor DarkGray
Write-Host '       attaches macOS artifacts, and publishes the release.' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  DO NOT manually publish the draft release — release.sh handles that.' -ForegroundColor Yellow
Write-Host ''
