#!/bin/bash

# Simple script to start an interactive session with Intel Iris GPU support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ubuntu-intel-iris-gl"

# Build image if it doesn't exist
if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "Building Docker image $IMAGE_NAME..."
    if ! docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"; then
        echo "❌ Failed to build Docker image"
        exit 1
    fi
    echo "✅ Docker image built successfully"
    echo ""
fi

echo "🚀 Starting interactive session with Intel Iris GPU support..."
echo "Container: $IMAGE_NAME"
echo "GPU: Intel Iris with Mesa OpenGL"
echo ""

# Start interactive container
docker run -it --rm \
    --name iris \
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
