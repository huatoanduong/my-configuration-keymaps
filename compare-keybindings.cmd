@echo off
echo Comparing VS Code keybindings files...
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "compare-keybindings.ps1"

echo.
echo Batch script completed!
@REM pause
