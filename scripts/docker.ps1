#!/usr/bin/env pwsh

param(
    [Parameter(Position=0)]
    [string]$Command,
    [switch]$h,
    [switch]$help
)

if ($h -or $help) {
    Write-Host "Usage: .\docker.ps1 [COMMAND]"
    Write-Host "Commands:"
    Write-Host "  start   Start persistent container"
    Write-Host "  attach  Attach to running container"
    Write-Host "  stop    Stop running container"
    exit 0
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH"
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ProjectName = Split-Path -Leaf $ProjectRoot

$DockerImage = "docker.io/kvasirio/rp2350:latest"
$ContainerName = "rp2350-$ProjectName"

# Convert Windows path to WSL/Linux path for Docker
$ProjectPath = $ProjectRoot -replace '\\', '/' -replace '^([A-Z]):', { $_.Value.ToLower() }

switch ($Command) {
    "start" {
        $existing = docker ps -q -f name=$ContainerName
        if ($existing) {
            Write-Warning "Container '$ContainerName' is already running"
            exit 0
        }

        Write-Host "Pulling latest Docker image..."
        docker pull $DockerImage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to pull Docker image"
            exit 1
        }

        Write-Host "Starting container: $ContainerName"
        docker run --rm -d --name $ContainerName -v "${ProjectPath}:/workspace/project" --privileged $DockerImage sleep infinity
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to start container"
            exit 1
        }
        Write-Host "Container started successfully"
    }
    "attach" {
        $existing = docker ps -q -f name=$ContainerName
        if (-not $existing) {
            Write-Error "Container '$ContainerName' is not running. Start it first with: .\docker.ps1 start"
            exit 1
        }

        Write-Host "Attaching to container: $ContainerName"
        docker exec -it $ContainerName fish
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to attach to container"
            exit 1
        }
    }
    "stop" {
        $existing = docker ps -aq -f name=$ContainerName
        if (-not $existing) {
            Write-Warning "Container '$ContainerName' does not exist"
            exit 0
        }

        Write-Host "Stopping container: $ContainerName"
        docker stop $ContainerName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to stop container"
            exit 1
        }
        Write-Host "Container stopped successfully"
    }
    default {
        Write-Host "Error: Invalid command. Use -h for help."
        exit 1
    }
}
