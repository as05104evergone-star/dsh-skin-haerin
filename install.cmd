@echo off
rem Haerin Skin installer wrapper: runs install.ps1 with a temporary
rem execution-policy bypass, because Windows defaults to Restricted.
rem Usage:  install.cmd [install^|uninstall^|status] [-DistPath "..."]
setlocal
set "SCRIPT=%~dp0install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "CODE=%ERRORLEVEL%"
if not "%CODE%"=="0" (
  echo.
  echo [haerin-skin] exited with code %CODE%
)
pause
exit /b %CODE%
