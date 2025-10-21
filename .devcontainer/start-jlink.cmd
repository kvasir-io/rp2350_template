@echo off
REM Start JLinkRemoteServer if not already running

where JLinkRemoteServerExe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo JLinkRemoteServer not found in PATH, skipping...
    exit /b 0
)

tasklist /FI "IMAGENAME eq JLinkRemoteServerExe.exe" 2>NUL | find /I /N "JLinkRemoteServerExe.exe">NUL
if %ERRORLEVEL% EQU 0 (
    echo JLinkRemoteServer is already running
) else (
    echo Starting JLinkRemoteServer...
    start /B JLinkRemoteServerExe -select USB
    timeout /t 2 /nobreak >nul
    echo JLinkRemoteServer started
)
