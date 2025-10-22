#!/bin/bash

set -e

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [BUILD_DIR] [CMAKE_FLAGS...]"
    echo ""
    echo "Configures the project using CMake and Clang"
    echo ""
    echo "Arguments:"
    echo "  BUILD_DIR      Build directory (default: docker_build)"
    echo "  CMAKE_FLAGS    Additional CMake configuration flags"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Configure in docker_build"
    echo "  $0 build                              # Configure in 'build' directory"
    echo "  $0 build -DJLINK_IP=192.168.1.100    # Configure with custom CMake flags"
    exit 0
fi

BUILD_DIR="${1:-docker_build}"
shift 2>/dev/null || true

# Check if we need to reconfigure
CONFIG_CACHE="${BUILD_DIR}/.cmake_config_cache"
CURRENT_CONFIG="CC=clang CXX=clang++ $*"
NEEDS_CONFIGURE=false

if [ ! -f "${BUILD_DIR}/CMakeCache.txt" ]; then
    NEEDS_CONFIGURE=true
    echo "Build directory not configured yet"
elif [ ! -f "${CONFIG_CACHE}" ]; then
    NEEDS_CONFIGURE=true
    echo "No configuration cache found"
elif [ "$(cat "${CONFIG_CACHE}")" != "${CURRENT_CONFIG}" ]; then
    NEEDS_CONFIGURE=true
    echo "Configuration changed:"
    echo "  Previous: $(cat "${CONFIG_CACHE}")"
    echo "  Current:  ${CURRENT_CONFIG}"
else
    echo "Configuration unchanged, skipping CMake configure step"
fi

if [ "${NEEDS_CONFIGURE}" = true ]; then
    echo "Configuring project in ${BUILD_DIR}..."
    mkdir -p "${BUILD_DIR}"
    env CC=clang CXX=clang++ cmake . -B "${BUILD_DIR}" "$@"
    echo "${CURRENT_CONFIG}" >"${CONFIG_CACHE}"
    echo "Configuration complete!"
else
    echo "Already configured"
fi

echo "Building peripherals headers"
cmake --build "${BUILD_DIR}" --target core_peripherals peripherals --parallel
echo "Peripheral headers build complete! Artifacts in ${BUILD_DIR}/"
