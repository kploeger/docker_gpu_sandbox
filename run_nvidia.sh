#!/bin/bash

# Script to run container with NVIDIA GPU support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="gpu-sandbox:nvidia"

# Check if NVIDIA runtime is available
if ! docker info 2>/dev/null | grep -i nvidia > /dev/null; then
    echo "⚠️  NVIDIA Docker runtime not detected."
    echo "Please install nvidia-container-toolkit:"
    echo "  sudo apt install nvidia-container-toolkit"
    echo "  sudo systemctl restart docker"
    echo ""
fi

# Build NVIDIA image if it doesn't exist
if ! docker images | grep -q "gpu-sandbox.*nvidia"; then
    echo "Building NVIDIA GPU Docker image..."
    if ! docker build -t "$IMAGE_NAME" --build-arg GPU_SUPPORT=nvidia --build-arg ENABLE_CUDA=true "$SCRIPT_DIR"; then
        echo "❌ Failed to build Docker image"
        exit 1
    fi
    echo "✅ Docker image built successfully"
    echo ""
fi

echo "🚀 Starting interactive session with NVIDIA GPU support..."
echo "Container: $IMAGE_NAME"
echo "GPU: NVIDIA with CUDA"
echo ""

# Start interactive container with NVIDIA GPU support
docker run -it --rm \
    --name nvidia-gpu \
    --gpus all \
    --device=/dev/dri:/dev/dri \
    --group-add video \
    -e DISPLAY=$DISPLAY \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    --security-opt seccomp=unconfined \
    --cap-add=SYS_PTRACE \
    "$IMAGE_NAME"
