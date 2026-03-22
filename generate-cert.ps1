#Requires -Version 5.1

<#
.SYNOPSIS
    Generates a self-signed code signing certificate for MSIX signing.
.DESCRIPTION
    Creates a self-signed CodeSigningCert with subject CN=DhikrAtWork Open Source,
    valid for 5 years. Exports the public certificate as DhikrAtWork.cer (to the
    repo root, safe to commit) and the private key as windows\signing\CERTIFICATE.pfx
    (gitignored, never committed).

    Run this once per development machine. If the .pfx is lost you must regenerate
    and all existing users will need to re-run Install.bat.
.PARAMETER Force
    Overwrite existing .pfx and .cer files without prompting.
.EXAMPLE
    .\generate-cert.ps1
    .\generate-cert.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$repoRoot    = $PSScriptRoot
$signingDir  = Join-Path $repoRoot 'windows\signing'
$pfxPath     = Join-Path $signingDir 'CERTIFICATE.pfx'
$cerPath     = Join-Path $repoRoot 'DhikrAtWork.cer'

# ---------------------------------------------------------------------------
# Guard: refuse to overwrite unless -Force is specified
# ---------------------------------------------------------------------------
if ((Test-Path $pfxPath) -and -not $Force) {
    Write-Error @"
A certificate already exists at:
  $pfxPath

If you want to regenerate it, run:
  .\generate-cert.ps1 -Force

WARNING: Regenerating a certificate will change the publisher identity.
All existing users will need to re-run Install.bat to trust the new certificate.
"@
    exit 1
}

# ---------------------------------------------------------------------------
# Ensure signing directory exists
# ---------------------------------------------------------------------------
if (-not (Test-Path $signingDir)) {
    New-Item -ItemType Directory -Path $signingDir -Force | Out-Null
    Write-Verbose "Created directory: $signingDir"
}

# ---------------------------------------------------------------------------
# Prompt for certificate password
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Enter a password to protect the .pfx private key file.'
Write-Host 'You will need this password when running release.ps1 (via MSIX_CERT_PASSWORD env var).'
Write-Host ''

$password = Read-Host -Prompt 'Certificate password' -AsSecureString
$confirm  = Read-Host -Prompt 'Confirm password'     -AsSecureString

# Compare SecureString values
$pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
$pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm))

if ($pwd1 -ne $pwd2) {
    Write-Error 'Passwords do not match. Aborting.'
    exit 1
}

if ([string]::IsNullOrEmpty($pwd1)) {
    Write-Error 'Password must not be empty. Aborting.'
    exit 1
}

# ---------------------------------------------------------------------------
# Generate the self-signed certificate
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating self-signed code signing certificate...'

$notAfter = (Get-Date).AddYears(5)

$certParams = @{
    Subject           = 'CN=DhikrAtWork Open Source'
    Type              = 'CodeSigningCert'
    KeyUsage          = 'DigitalSignature'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter          = $notAfter
    HashAlgorithm     = 'SHA256'
}

$cert = New-SelfSignedCertificate @certParams

Write-Verbose "Certificate thumbprint: $($cert.Thumbprint)"
Write-Verbose "Certificate valid until: $($cert.NotAfter)"

# ---------------------------------------------------------------------------
# Export .cer (DER-encoded public certificate — safe to commit)
# ---------------------------------------------------------------------------
Write-Host "Exporting public certificate: $cerPath"
Export-Certificate -Cert $cert -FilePath $cerPath -Type CERT -Force | Out-Null

# ---------------------------------------------------------------------------
# Export .pfx (private key — NEVER commit, gitignored via *.pfx)
# ---------------------------------------------------------------------------
Write-Host "Exporting private key bundle: $pfxPath"
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password -Force | Out-Null

# ---------------------------------------------------------------------------
# Optionally remove the cert from the user store (it lives in the .pfx now)
# ---------------------------------------------------------------------------
Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
Write-Verbose 'Removed certificate from CurrentUser\My store.'

# ---------------------------------------------------------------------------
# Success message
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=========================================================' -ForegroundColor Green
Write-Host '  Certificate generated successfully!' -ForegroundColor Green
Write-Host '=========================================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Files created:'
Write-Host "  Public  (.cer): $cerPath"
Write-Host "  Private (.pfx): $pfxPath"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Commit DhikrAtWork.cer to the repository (it is safe to share).'
Write-Host '  2. NEVER commit windows\signing\CERTIFICATE.pfx (it is gitignored).'
Write-Host '  3. Store the certificate password securely (e.g., in a password manager).'
Write-Host '  4. Set MSIX_CERT_PASSWORD=<your password> when running release.ps1.'
Write-Host '     The pubspec.yaml placeholder YOUR_CERT_PASSWORD is never replaced.'
Write-Host ''
Write-Host 'Certificate details:'
Write-Host "  Subject : CN=DhikrAtWork Open Source"
Write-Host "  Valid to: $($notAfter.ToString('yyyy-MM-dd'))"
Write-Host ''
