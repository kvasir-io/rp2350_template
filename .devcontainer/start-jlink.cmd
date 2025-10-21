@echo off
setlocal enabledelayedexpansion

set "JLINK_EXE="
set "LATEST_VER=0"

REM --- Search in Program Files (64-bit) ---
for /d %%D in ("C:\Program Files\SEGGER\JLink_V*") do (
    set "DIRNAME=%%~nD"
    for /f "tokens=2 delims=_V" %%V in ("!DIRNAME!") do (
        set /a "VER=%%V"
        if !VER! gtr !LATEST_VER! (
            set "LATEST_VER=!VER!"
            set "JLINK_EXE=%%~D\JLinkRemoteServer.exe"
        )
    )
)

REM --- Search in Program Files (x86) ---
for /d %%D in ("C:\Program Files (x86)\SEGGER\JLink_V*") do (
    set "DIRNAME=%%~nD"
    for /f "tokens=2 delims=_V" %%V in ("!DIRNAME!") do (
        set /a "VER=%%V"
        if !VER! gtr !LATEST_VER! (
            set "LATEST_VER=!VER!"
            set "JLINK_EXE=%%~D\JLinkRemoteServer.exe"
        )
    )
)

REM --- Fallback: check PATH ---
if not defined JLINK_EXE (
    for %%A in (JLinkRemoteServer.exe) do (
        where /q %%A && for /f "delims=" %%B in ('where %%A') do set "JLINK_EXE=%%B"
    )
)

if not defined JLINK_EXE (
    echo JLinkRemoteServer not found, skipping...
    exit /b 0
)

tasklist /FI "IMAGENAME eq JLinkRemoteServer.exe" 2>NUL | find /I "JLinkRemoteServer.exe" >NUL
if %ERRORLEVEL% EQU 0 (
    echo JLinkRemoteServer is already running.
) else (
    echo Starting JLinkRemoteServer (version !LATEST_VER!)...
    start /B "%JLINK_EXE%" -select USB -nolog
    timeout /t 2 /nobreak >nul
    echo JLinkRemoteServer started.
)

endlocal
exit /b 0
