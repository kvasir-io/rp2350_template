#!/bin/bash

set -e

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [BUILD_DIR] [CMAKE_FLAGS...]"
    echo ""
    echo "Configures and builds the project using CMake and Clang"
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

if [ $# -eq 0 ]; then
    set -- "-DUSE_FORCE_FETCH=ON"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/configure.sh" "$BUILD_DIR" "$@"

# Build all targets
echo "Building all targets..."
cmake --build "${BUILD_DIR}" --parallel

echo "Build complete! Artifacts in ${BUILD_DIR}/"
