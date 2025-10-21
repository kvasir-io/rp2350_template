setlocal

set "JLINK_EXE="

if exist "C:\Program Files\SEGGER\JLink\JLinkRemoteServer.exe" set "JLINK_EXE=C:\Program Files\SEGGER\JLink\JLinkRemoteServer.exe"
if exist "C:\Program Files (x86)\SEGGER\JLink\JLinkRemoteServer.exe" set "JLINK_EXE=C:\Program Files (x86)\SEGGER\JLink\JLinkRemoteServer.exe"

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
    echo Starting JLinkRemoteServer...
    start /B "%JLINK_EXE%" -select USB -nolog
    timeout /t 2 /nobreak >nul
    echo JLinkRemoteServer started.
)

endlocal
exit /b 0
