@echo off
setlocal enabledelayedexpansion

:: Detect script directory
set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%jlink.conf"
set "JLINK_IP="

:: Step 1: Read manual override from jlink.conf if exists
if exist "%CONFIG_FILE%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
        if /i "%%a"=="JLINK_IP" (
            set "JLINK_IP=%%b"
            for /f "tokens=* delims= " %%x in ("!JLINK_IP!") do set "JLINK_IP=%%x"
        )
    )
)

:: Step 2: If not set or set to auto, use PowerShell to resolve host.docker.internal
if not defined JLINK_IP (
    goto resolve
) else (
    if /i "%JLINK_IP%"=="auto" goto resolve
    echo Using manual override: JLINK_IP=%JLINK_IP%
    goto write_env
)

:resolve
:: Call PowerShell script to get host machine IP address
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%get-host-ip.ps1"') do (
    set "JLINK_IP=%%i"
)

:: Fallback
if not defined JLINK_IP (
    echo Failed to detect host IP. Defaulting to 127.0.0.1
    set "JLINK_IP=127.0.0.1"
) else (
    echo Detected host machine IP: %JLINK_IP%
)

:write_env
:: Write to .env
echo JLINK_IP=%JLINK_IP%> "%SCRIPT_DIR%.env"
echo Wrote .env file: JLINK_IP=%JLINK_IP%

exit /b 0
