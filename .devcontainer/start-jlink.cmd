@echo off
setlocal enabledelayedexpansion

set JLINK_EXE=

for /d %%D in ("C:\Program Files\SEGGER\JLink_V*") do set JLINK_EXE=%%D\JLinkRemoteServer.exe

if not defined JLINK_EXE for /d %%D in ("C:\Program Files (x86)\SEGGER\JLink_V*") do set JLINK_EXE=%%D\JLinkRemoteServer.exe

if not defined JLINK_EXE exit /b 0

if not exist "!JLINK_EXE!" exit /b 0

tasklist /FI "IMAGENAME eq JLinkRemoteServer.exe" 2>nul | find /I "JLinkRemoteServer.exe" >nul
if not errorlevel 1 exit /b 0

start /B "!JLINK_EXE!" -select USB -nolog
timeout /t 2 /nobreak >nul

exit /b 0
