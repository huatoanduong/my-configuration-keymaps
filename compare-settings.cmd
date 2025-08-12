@echo off
echo Comparing VS Code settings files...
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "compare-settings.ps1"

echo.
echo Batch script completed!
@REM pause
