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

# Auto-detect container engine (prefer docker, fallback to podman)
if command -v docker >/dev/null 2>&1; then
    DOCKER_CMD=docker
    USER_MAPPING_FLAGS="-e LOCAL_USER_ID=$(id -u "$USER") -e LOCAL_GROUP_ID=$(id -g "$USER")"
    EXEC_USER_FLAGS="-u $(id -u "$USER"):$(id -g "$USER")"
elif command -v podman >/dev/null 2>&1; then
    DOCKER_CMD=podman
    USER_MAPPING_FLAGS="--userns=keep-id"
    EXEC_USER_FLAGS=""
else
    echo "Error: Neither docker nor podman found!"
    exit 1
fi

DOCKER_IMAGE="docker.io/kvasirio/rp2350:latest"
CONTAINER_NAME="rp2350-$(basename "${PROJECT_ROOT}")"

if [ "$1" = "start" ]; then
    if $DOCKER_CMD ps -q -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Warning: Container '${CONTAINER_NAME}' is already running"
        exit 0
    fi

    echo "Pulling latest container image..."
    if ! $DOCKER_CMD pull "${DOCKER_IMAGE}"; then
        echo "Error: Failed to pull container image"
        exit 1
    fi

    echo "Starting container: ${CONTAINER_NAME}"
    if ! $DOCKER_CMD run --rm -d --name "${CONTAINER_NAME}" -v "${PROJECT_ROOT}/:/workspace/project" --privileged --network=host ${USER_MAPPING_FLAGS} "${DOCKER_IMAGE}" sleep infinity; then
        echo "Error: Failed to start container"
        exit 1
    fi
    echo "Container started successfully"

elif [ "$1" = "attach" ]; then
    if ! $DOCKER_CMD ps -q -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Error: Container '${CONTAINER_NAME}' is not running. Start it first with: $0 start"
        exit 1
    fi

    echo "Attaching to container: ${CONTAINER_NAME}"
    if ! $DOCKER_CMD exec -it ${EXEC_USER_FLAGS} "${CONTAINER_NAME}" fish; then
        echo "Error: Failed to attach to container"
        exit 1
    fi

elif [ "$1" = "stop" ]; then
    if ! $DOCKER_CMD ps -aq -f name="${CONTAINER_NAME}" | grep -q .; then
        echo "Warning: Container '${CONTAINER_NAME}' does not exist"
        exit 0
    fi

    echo "Stopping container: ${CONTAINER_NAME}"
    if ! $DOCKER_CMD stop "${CONTAINER_NAME}"; then
        echo "Error: Failed to stop container"
        exit 1
    fi
    echo "Container stopped successfully"

else
    echo "Error: Invalid option. Use -h for help."
    exit 1
fi
