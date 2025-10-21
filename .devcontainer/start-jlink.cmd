@echo off
setlocal enabledelayedexpansion

set JLINK_EXE=
set TMP_DIR=%TEMP%\JLinkTemp

:: Create a temporary directory for JLinkRemoteServer to run in
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

:: Search in "Program Files" for JLink
for /d %%D in ("C:\Program Files\SEGGER\JLink_V*") do (
    set JLINK_EXE=%%D\JLinkRemoteServer.exe
)

:: If not found, search in "Program Files (x86)"
if not defined JLINK_EXE (
    for /d %%D in ("C:\Program Files (x86)\SEGGER\JLink_V*") do (
        set JLINK_EXE=%%D\JLinkRemoteServer.exe
    )
)

:: If still not found, exit
if not defined JLINK_EXE exit /b 0

:: If JLinkRemoteServer.exe doesn't exist, exit
if not exist "!JLINK_EXE!" exit /b 0

:: Check if JLinkRemoteServer.exe is already running
tasklist /FI "IMAGENAME eq JLinkRemoteServer.exe" 2>nul | find /I "JLinkRemoteServer.exe" >nul
if not errorlevel 1 exit /b 0

:: Start JLinkRemoteServer.exe in the temporary directory
start /B "" cmd /C "cd /d %TMP_DIR% && "!JLINK_EXE!" -select USB"

:: Wait for a couple of seconds to ensure it starts
timeout /t 2 /nobreak >nul

exit /b 0
