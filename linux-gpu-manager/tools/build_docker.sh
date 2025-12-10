#!/bin/bash
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="driver-pilot-builder"

# Usage check
if [ "$1" == "" ]; then
    echo "Usage: ./tools/build_docker.sh [amd64|arm64|all]"
    echo "Example: ./tools/build_docker.sh amd64"
    exit 1
fi

TARGET_ARCH=$1

build_arch() {
    ARCH=$1
    PLATFORM="linux/$ARCH"
    
    echo "========================================"
    echo "Building for Architecture: $ARCH"
    echo "Platform: $PLATFORM"
    echo "========================================"

    echo "[1/2] Building Docker Image..."
    # Build image compatible with target platform
    docker build --platform $PLATFORM -t ${IMAGE_NAME}:$ARCH "$PROJECT_ROOT"

    echo "[2/2] Running Build Container..."
    # Mount project root to /app to get the output artifacts
    docker run --platform $PLATFORM --rm -v "$PROJECT_ROOT:/app" ${IMAGE_NAME}:$ARCH \
        python3 tools/build_deb.py --arch $ARCH
        
    echo "[OK] Build completed for $ARCH"
}

if [ "$TARGET_ARCH" == "all" ]; then
    build_arch "amd64"
    build_arch "arm64"
else
    build_arch "$TARGET_ARCH"
fi
