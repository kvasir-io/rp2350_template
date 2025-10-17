#!/bin/bash

set -e

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  start   Start persistent container"
    echo "  attach  Attach to running container"
    echo "  stop    Stop running container"
    exit 0
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker not found!"
    exit 1
fi

DOCKER_IMAGE="docker.io/kvasirio/rp2350:latest"
CONTAINER_NAME="rp2350-$(basename "${PROJECT_ROOT}")"
USER_MAPPING_FLAGS="-e LOCAL_USER_ID=$(id -u "$USER") -e LOCAL_GROUP_ID=$(id -g "$USER")"

if [ "$1" = "start" ]; then
    if docker ps -q -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Warning: Container '${CONTAINER_NAME}' is already running"
        exit 0
    fi

    echo "Pulling latest Docker image..."
    if ! docker pull "${DOCKER_IMAGE}"; then
        echo "Error: Failed to pull Docker image"
        exit 1
    fi

    echo "Starting container: ${CONTAINER_NAME}"
    if ! docker run --rm -d --name "${CONTAINER_NAME}" -v "${PROJECT_ROOT}/:/workspace/project" --privileged ${USER_MAPPING_FLAGS} "${DOCKER_IMAGE}" sleep infinity; then
        echo "Error: Failed to start container"
        exit 1
    fi
    echo "Container started successfully"

elif [ "$1" = "attach" ]; then
    if ! docker ps -q -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Error: Container '${CONTAINER_NAME}' is not running. Start it first with: $0 start"
        exit 1
    fi

    echo "Attaching to container: ${CONTAINER_NAME}"
    if ! docker exec -it -u "$(id -u "$USER"):$(id -g "$USER")" "${CONTAINER_NAME}" fish; then
        echo "Error: Failed to attach to container"
        exit 1
    fi

elif [ "$1" = "stop" ]; then
    if ! docker ps -aq -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Warning: Container '${CONTAINER_NAME}' does not exist"
        exit 0
    fi

    echo "Stopping container: ${CONTAINER_NAME}"
    if ! docker stop "${CONTAINER_NAME}"; then
        echo "Error: Failed to stop container"
        exit 1
    fi
    echo "Container stopped successfully"

else
    echo "Error: Invalid option. Use -h for help."
    exit 1
fi
