@echo off
rem QUERVEX uninstaller for Windows - double-click friendly wrapper around uninstall.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
set QUERVEX_EXIT=%ERRORLEVEL%
rem Keep the window open when launched by double-click
echo %cmdcmdline% | find /i "%~0" >nul && pause
exit /b %QUERVEX_EXIT%
