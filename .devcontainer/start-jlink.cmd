@echo off
setlocal

REM --- Auto-detect JLinkRemoteServer.exe ---
set "JLINK_EXE="

if exist "C:\Program Files\SEGGER\JLink\JLinkRemoteServer.exe" set "JLINK_EXE=C:\Program Files\SEGGER\JLink\JLinkRemoteServer.exe"
if exist "C:\Program Files (x86)\SEGGER\JLink\JLinkRemoteServer.exe" set "JLINK_EXE=C:\Program Files (x86)\SEGGER\JLink\JLinkRemoteServer.exe"

if not defined JLINK_EXE (
    for %%A in (JLinkRemoteServer.exe) do (
        where /q %%A && for /f "delims=" %%B in ('where %%A') do set "JLINK_EXE=%%B"
    )
)

if not defined JLINK_EXE (
    if exist "%~dp0JLinkRemoteServer.exe" set "JLINK_EXE=%~dp0JLinkRemoteServer.exe"
)

if not defined JLINK_EXE exit /b 0

REM --- Skip if already running ---
tasklist /FI "IMAGENAME eq JLinkRemoteServer.exe" 2>NUL | find /I "JLinkRemoteServer.exe" >NUL && exit /b 0

REM --- Start silently ---
start "" "%JLINK_EXE%" -select USB -nolog -port 19020

endlocal
exit /b 0
