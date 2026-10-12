@echo off
rem QUERVEX installer for Windows - double-click friendly wrapper around install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set QUERVEX_EXIT=%ERRORLEVEL%
rem Keep the window open when launched by double-click
echo %cmdcmdline% | find /i "%~0" >nul && pause
exit /b %QUERVEX_EXIT%
