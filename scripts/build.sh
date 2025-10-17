#!/bin/bash

set -e

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [BUILD_DIR] [CMAKE_FLAGS...]"
    echo ""
    echo "Builds the project using CMake and Clang"
    echo ""
    echo "Arguments:"
    echo "  BUILD_DIR      Build directory (default: docker_build)"
    echo "  CMAKE_FLAGS    Additional CMake configuration flags"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build in docker_build"
    echo "  $0 build                              # Build in 'build' directory"
    echo "  $0 build -DJLINK_IP=192.168.1.100    # Build with custom CMake flags"
    exit 0
fi

BUILD_DIR="${1:-docker_build}"
shift 2>/dev/null || true

echo "Configuring project in ${BUILD_DIR}..."
mkdir -p "${BUILD_DIR}"
env CC=clang CXX=clang++ cmake . -B "${BUILD_DIR}" "$@"

echo "Building..."
cmake --build "${BUILD_DIR}" --parallel "$(nproc)"

echo "Build complete! Artifacts in ${BUILD_DIR}/"
