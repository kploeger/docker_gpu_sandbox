#!/bin/bash

# Script to run container with integrated graphics support (Intel/AMD APU)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="gpu-sandbox:integrated"

# Build integrated graphics image if it doesn't exist  
if ! docker images | grep -q "gpu-sandbox.*integrated"; then
    echo "Building integrated graphics Docker image..."
    if ! docker build -t "$IMAGE_NAME" --build-arg GPU_SUPPORT=integrated "$SCRIPT_DIR"; then
        echo "❌ Failed to build Docker image"
        exit 1
    fi
    echo "✅ Docker image built successfully"
    echo ""
fi

echo "🚀 Starting interactive session with integrated graphics support..."
echo "Container: $IMAGE_NAME"
echo "GPU: Intel integrated / AMD APU with Mesa OpenGL"
echo ""

# Start interactive container with integrated graphics support
docker run -it --rm \
    --name integrated-gpu \
    --device=/dev/dri:/dev/dri \
    --group-add video \
    -e DISPLAY=$DISPLAY \
    -e LIBGL_ALWAYS_INDIRECT=0 \
    -e LIBGL_ALWAYS_SOFTWARE=0 \
    -e MESA_GL_VERSION_OVERRIDE=3.3 \
    -e MESA_GLSL_VERSION_OVERRIDE=330 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    --security-opt seccomp=unconfined \
    --cap-add=SYS_PTRACE \
    "$IMAGE_NAME"
