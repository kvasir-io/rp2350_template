#!/usr/bin/env pwsh
# Start JLinkRemoteServer if not already running

if (Get-Command JLinkRemoteServerExe -ErrorAction SilentlyContinue) {
    $process = Get-Process -Name JLinkRemoteServerExe -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "JLinkRemoteServer is already running"
    } else {
        Write-Host "Starting JLinkRemoteServer..."
        $null = Start-Process -FilePath "JLinkRemoteServerExe" -ArgumentList "-select","USB" -WorkingDirectory $env:TEMP -PassThru
        Start-Sleep -Seconds 2
        Write-Host "JLinkRemoteServer started"
    }
} else {
    Write-Host "JLinkRemoteServer not found in PATH, skipping..."
}
