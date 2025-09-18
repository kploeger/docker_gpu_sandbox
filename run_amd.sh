#!/bin/bash

# Script to run container with AMD dedicated GPU support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="gpu-sandbox:amd"

# Build AMD dedicated GPU image if it doesn't exist
if ! docker images | grep -q "gpu-sandbox.*amd"; then
    echo "Building AMD dedicated GPU Docker image..."
    if ! docker build -t "$IMAGE_NAME" --build-arg GPU_SUPPORT=amd --build-arg ENABLE_ROCM=true "$SCRIPT_DIR"; then
        echo "❌ Failed to build Docker image"
        exit 1
    fi
    echo "✅ Docker image built successfully"
    echo ""
fi

echo "🚀 Starting interactive session with AMD dedicated GPU support..."
echo "Container: $IMAGE_NAME"
echo "GPU: AMD dedicated with ROCm"
echo ""

# Start interactive container with AMD dedicated GPU support
docker run -it --rm \
    --name amd-gpu \
    --device=/dev/dri:/dev/dri \
    --device=/dev/kfd:/dev/kfd \
    --group-add video \
    --group-add $(stat -c '%g' /dev/kfd 2>/dev/null || echo "render") \
    -e DISPLAY=$DISPLAY \
    -e HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    -e LIBGL_ALWAYS_INDIRECT=0 \
    -e LIBGL_ALWAYS_SOFTWARE=0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    --security-opt seccomp=unconfined \
    --cap-add=SYS_PTRACE \
    "$IMAGE_NAME"
