@echo off
REM Main Launcher Batch File
REM Finds the Launcher.ps1 script in the ./assets/ folder

echo ================================
echo    All-In-One Tool Launcher
echo ================================
echo.

REM Set the path to the PowerShell launcher script
set "LAUNCHER_PS=%~dp0assets\Launcher.ps1"

REM Check if the launcher script exists
if not exist "%LAUNCHER_PS%" (
    echo ERROR: Launcher script not found!
    echo.
    echo Expected it at: %LAUNCHER_PS%
    echo.
    echo Please make sure the 'assets' folder is present.
    pause
    exit /b 1
)

REM Run the PowerShell launcher script
powershell -ExecutionPolicy Bypass -File "%LAUNCHER_PS%"