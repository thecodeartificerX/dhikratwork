#Requires -Version 5.1

<#
.SYNOPSIS
    Launches DhikrAtWork in debug mode with hot reload.
.DESCRIPTION
    Runs 'flutter run -d windows' from the project root.
    Press r for hot reload, R for hot restart, q to quit.
.PARAMETER Release
    Run in release mode instead of debug.
.EXAMPLE
    .\run.ps1
.EXAMPLE
    .\run.ps1 -Release
#>

[CmdletBinding()]
param(
    [switch]$Release
)

Set-StrictMode -Version Latest

$args_ = @('run', '-d', 'windows')
if ($Release) { $args_ += '--release' }

Write-Host "Starting DhikrAtWork ($( if ($Release) { 'release' } else { 'debug' } ))..." -ForegroundColor Cyan
Write-Host "  r = hot reload  |  R = hot restart  |  q = quit" -ForegroundColor DarkGray
Write-Host ""

& flutter @args_
