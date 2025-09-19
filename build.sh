#!/bin/bash

# Docker GPU Sandbox - Build Script
#
# USAGE:
#   ./build.sh              # Fast build (Intel/NVIDIA support only)
#   ./build.sh amd          # Full build with AMD GPU drivers (slower)
#
# DESCRIPTION:
#   Builds a Docker image with hardware OpenGL acceleration support.
#   The default build is optimized for speed and supports Intel integrated
#   graphics and NVIDIA GPUs. AMD GPU support can be enabled but requires
#   additional driver packages that significantly increase build time.
#
# IMAGES CREATED:
#   gpu-sandbox:gl          # Fast build (default)
#   gpu-sandbox:gl-amd      # With AMD GPU drivers
#
# EXAMPLES:
#   ./build.sh              # Quick build for most users
#   ./build.sh amd          # If you have AMD dedicated GPU
#

# Script to build Docker image with hardware GL support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="gpu-sandbox:gl"

# Check for AMD GPU flag
INCLUDE_AMD_GPU="${1:-false}"
if [ "$INCLUDE_AMD_GPU" = "amd" ]; then
    INCLUDE_AMD_GPU="true"
    IMAGE_NAME="gpu-sandbox:gl-amd"
    echo "🔨 Building Docker image with hardware GL support (including AMD GPU drivers)..."
else
    INCLUDE_AMD_GPU="false"
    echo "🔨 Building Docker image with hardware GL support (fast build, no AMD drivers)..."
fi

echo "Image: $IMAGE_NAME"
echo "AMD GPU support: $INCLUDE_AMD_GPU"
echo ""

if docker build -t "$IMAGE_NAME" --build-arg AMD_GPU="$INCLUDE_AMD_GPU" "$SCRIPT_DIR"; then
    echo "✅ Successfully built $IMAGE_NAME"
    echo ""
    echo "Image size:"
    docker images | grep "gpu-sandbox" | grep "gl"
    echo ""
    echo "Usage:"
    if [ "$INCLUDE_AMD_GPU" = "true" ]; then
        echo "  ./run_gl.sh    # Will use gpu-sandbox:gl-amd automatically for AMD systems"
    else
        echo "  ./run_gl.sh    # Fast build for Intel/NVIDIA (to include AMD: ./build_all.sh amd)"
    fi
else
    echo "❌ Failed to build $IMAGE_NAME"
    exit 1
fi
