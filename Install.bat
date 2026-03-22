@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  DhikrAtWork Installer
REM  Imports the self-signed certificate and installs the MSIX.
REM  Must run as Administrator — this script self-elevates.
REM ============================================================

REM --- Check for Administrator rights ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    echo.

    REM Re-launch this script elevated via VBScript ShellExecute
    set "SCRIPT=%~f0"
    set "VBS=%TEMP%\elevate_dhikratwork.vbs"

    > "!VBS!" echo Set oShell = CreateObject("Shell.Application")
    >> "!VBS!" echo oShell.ShellExecute "cmd.exe", "/c """ & "!SCRIPT!" & """", "", "runas", 1
    >> "!VBS!" echo Set oShell = Nothing

    cscript //nologo "!VBS!"
    del /q "!VBS!" 2>nul
    exit /b 0
)

REM --- Running as Administrator ---
echo.
echo  DhikrAtWork Installer
echo  ==================================================
echo.

REM Locate files relative to this .bat
set "BAT_DIR=%~dp0"
set "CERT_FILE=%BAT_DIR%DhikrAtWork.cer"
set "MSIX_FILE="

REM Find the .msix in the same directory
for %%f in ("%BAT_DIR%*.msix") do (
    set "MSIX_FILE=%%f"
)

REM --- Validate required files exist ---
if not exist "%CERT_FILE%" (
    echo [ERROR] DhikrAtWork.cer not found in:
    echo         %BAT_DIR%
    echo.
    echo Please ensure all files from the distribution zip are in the same folder.
    goto :FAILURE
)

if "!MSIX_FILE!" == "" (
    echo [ERROR] No .msix package found in:
    echo         %BAT_DIR%
    echo.
    echo Please ensure all files from the distribution zip are in the same folder.
    goto :FAILURE
)

REM --- Step 1: Import certificate into Trusted Root ---
echo [1/2] Importing DhikrAtWork certificate into Trusted Root store...
echo       This allows Windows to trust the application package.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Import-Certificate -FilePath '%CERT_FILE%' -CertStoreLocation Cert:\LocalMachine\Root | Out-Null; Write-Host '      Certificate imported successfully.' } catch { Write-Host \"      [ERROR] Certificate import failed: $($_.Exception.Message)\"; exit 1 }"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to import the certificate. Installation cannot continue.
    goto :FAILURE
)

echo.

REM --- Step 2: Install the MSIX package ---
echo [2/2] Installing DhikrAtWork (!MSIX_FILE!)...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Add-AppxPackage -Path '!MSIX_FILE!' -ErrorAction Stop; Write-Host '      DhikrAtWork installed successfully.' } catch { if ($_.Exception.Message -like '*already installed*' -or $_.Exception.Message -like '*higher version*') { Write-Host '      DhikrAtWork is already installed (same or newer version).'; exit 0 } else { Write-Host \"      [ERROR] Installation failed: $($_.Exception.Message)\"; exit 1 } }"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to install DhikrAtWork.
    goto :FAILURE
)

echo.
echo  ==================================================
echo  Installation complete!
echo.
echo  DhikrAtWork is now available in your Start Menu.
echo  Search for "DhikrAtWork" to launch it.
echo  ==================================================
echo.
pause
exit /b 0

:FAILURE
echo.
echo  ==================================================
echo  Installation failed. See error above.
echo.
echo  For help, visit:
echo  https://github.com/thecodeartificerX/dhikratwork
echo  ==================================================
echo.
pause
exit /b 1
