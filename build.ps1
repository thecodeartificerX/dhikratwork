#Requires -Version 5.1

<#
.SYNOPSIS
    Builds, tests, and validates the DhikrAtWork Flutter Windows app.
.DESCRIPTION
    Automates the full build pipeline: clean, pub get, analyze, test, build.
    Each step's errors are captured and displayed in a copy-friendly block.
    Use -SkipClean to keep cached build artifacts.
    Use -SkipTests to skip the test suite for faster iteration.
.PARAMETER SkipClean
    Skip 'flutter clean' to preserve cached build artifacts.
.PARAMETER SkipTests
    Skip 'flutter test' for faster builds when only checking compilation.
.PARAMETER Release
    Build in release mode (default). Use -Release:$false for debug.
.EXAMPLE
    .\build.ps1
    Full clean build with all checks.
.EXAMPLE
    .\build.ps1 -SkipClean -SkipTests
    Quick rebuild without cleaning or testing.
#>

[CmdletBinding()]
param(
    [switch]$SkipClean,
    [switch]$SkipTests,
    [switch]$Release = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Configuration ---
$ProjectRoot = $PSScriptRoot
$BuildMode = if ($Release) { 'release' } else { 'debug' }
$ExePath = Join-Path $ProjectRoot "build\windows\x64\runner\$($BuildMode.Substring(0,1).ToUpper() + $BuildMode.Substring(1))\dhikratwork.exe"

# --- Helpers ---
function Write-StepHeader {
    param([string]$Step, [string]$Description)
    Write-Host ""
    Write-Host "[$Step] $Description" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

function Write-Pass {
    param([string]$Message)
    Write-Host "  PASS  $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  FAIL  $Message" -ForegroundColor Red
}

function Invoke-BuildStep {
    <#
    .SYNOPSIS
        Runs a flutter command, captures output, and returns success/failure.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$StepName,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [int]$TimeoutSeconds = 600
    )

    Write-StepHeader -Step $StepName -Description $Description

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'flutter'
    $psi.Arguments = $Arguments -join ' '
    $psi.WorkingDirectory = $ProjectRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $exited = $process.WaitForExit($TimeoutSeconds * 1000)

    if (-not $exited) {
        $process.Kill()
        Write-Fail "$Description timed out after ${TimeoutSeconds}s"
        return @{ Success = $false; Output = "TIMEOUT after ${TimeoutSeconds}s" }
    }

    $exitCode = $process.ExitCode
    # Flutter writes progress/info to stderr even on success — combine both streams
    $fullOutput = @($stdout, $stderr) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd() }
    $combined = $fullOutput -join "`n"

    if ($exitCode -eq 0) {
        Write-Pass $Description
        return @{ Success = $true; Output = $combined }
    }
    else {
        Write-Fail "$Description (exit code $exitCode)"
        return @{ Success = $false; Output = $combined }
    }
}

# --- Main Pipeline ---
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$failedSteps = [System.Collections.Generic.List[hashtable]]::new()

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  DhikrAtWork Build Pipeline" -ForegroundColor Yellow
Write-Host "  Mode: $BuildMode" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Step 1: Clean
if (-not $SkipClean) {
    $result = Invoke-BuildStep -StepName '1/5' -Description 'flutter clean' -Arguments 'clean'
    if (-not $result.Success) { $failedSteps.Add(@{ Step = 'clean'; Output = $result.Output }) }
}
else {
    Write-StepHeader -Step '1/5' -Description 'flutter clean (SKIPPED)'
}

# Step 2: Pub Get
$stepNum = if ($SkipTests) { '2/4' } else { '2/5' }
$result = Invoke-BuildStep -StepName $stepNum -Description 'flutter pub get' -Arguments 'pub', 'get'
$pubGetFailed = $false
if (-not $result.Success) {
    $failedSteps.Add(@{ Step = 'pub get'; Output = $result.Output })
    $pubGetFailed = $true
    Write-Host ""
    Write-Fail "pub get failed — skipping remaining steps."
}

if (-not $pubGetFailed) {
    # Step 3: Analyze
    $stepNum = if ($SkipTests) { '3/4' } else { '3/5' }
    $result = Invoke-BuildStep -StepName $stepNum -Description 'flutter analyze' -Arguments 'analyze'
    if (-not $result.Success) {
        $failedSteps.Add(@{ Step = 'analyze'; Output = $result.Output })
    }

    # Step 4: Test
    if (-not $SkipTests) {
        $result = Invoke-BuildStep -StepName '4/5' -Description 'flutter test' -Arguments 'test' -TimeoutSeconds 300
        if (-not $result.Success) {
            $failedSteps.Add(@{ Step = 'test'; Output = $result.Output })
        }
    }
    else {
        Write-StepHeader -Step '4/5' -Description 'flutter test (SKIPPED)'
    }

    # Step 5: Build
    $stepNum = if ($SkipTests) { '4/4' } else { '5/5' }
    $buildArgs = @('build', 'windows', "--$BuildMode")
    $result = Invoke-BuildStep -StepName $stepNum -Description "flutter build windows --$BuildMode" -Arguments $buildArgs -TimeoutSeconds 600
    if (-not $result.Success) {
        $failedSteps.Add(@{ Step = 'build'; Output = $result.Output })
    }
}

# --- Validate Output ---
$timer.Stop()

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Validation" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

if (Test-Path $ExePath) {
    $fileInfo = Get-Item $ExePath
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Pass "dhikratwork.exe exists ($sizeMB MB)"
    Write-Host "  Path: $ExePath" -ForegroundColor DarkGray

    # Check for expected DLLs
    $buildDir = Split-Path $ExePath
    $expectedDlls = @('flutter_windows.dll', 'sqlite3.dll')
    foreach ($dll in $expectedDlls) {
        $dllPath = Join-Path $buildDir $dll
        if (Test-Path $dllPath) {
            Write-Pass "$dll present"
        }
        else {
            Write-Fail "$dll MISSING from build output"
        }
    }

    # Check data directory
    $dataDir = Join-Path $buildDir 'data'
    if (Test-Path $dataDir) {
        Write-Pass "data/ directory present"
    }
    else {
        Write-Fail "data/ directory MISSING"
    }
}
else {
    Write-Fail "dhikratwork.exe NOT FOUND at expected path"
    Write-Host "  Expected: $ExePath" -ForegroundColor DarkGray
}

# --- Summary ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Duration: $([math]::Round($timer.Elapsed.TotalSeconds, 1))s" -ForegroundColor DarkGray

if ($failedSteps.Count -eq 0) {
    Write-Host ""
    Write-Host "  ALL STEPS PASSED" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# --- Error Report (copy-friendly) ---
Write-Host ""
Write-Host "  $($failedSteps.Count) STEP(S) FAILED" -ForegroundColor Red
Write-Host ""
Write-Host "Copy everything between the markers and send to Claude:" -ForegroundColor Yellow
Write-Host ""
Write-Host "===== BUILD ERRORS START =====" -ForegroundColor Magenta

foreach ($failure in $failedSteps) {
    Write-Host ""
    Write-Host "--- [$($failure.Step)] ---"
    Write-Host $failure.Output
}

Write-Host ""
Write-Host "===== BUILD ERRORS END =====" -ForegroundColor Magenta
Write-Host ""

exit 1
