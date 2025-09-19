#!/bin/bash

# Docker GPU Sandbox - Run Script
#
# USAGE:
#   ./run.sh                # Auto-detect GPU and run interactively
#   ./run.sh [command]      # Run with custom command
#
# DESCRIPTION:
#   Automatically detects your GPU type (Intel, AMD, NVIDIA) and runs
#   the appropriate Docker container with hardware OpenGL acceleration.
#   
#   NOTE: You must build the image first with ./build.sh
#
# EXAMPLES:
#   ./build.sh                         # Build image first
#   ./run.sh                           # Interactive bash session
#   ./run.sh glxinfo                   # Test OpenGL
#   ./run.sh python3 /test_script.py   # Run custom command
#
#   # Run MuJoCo viewer with included ant model:
#   ./run.sh python3 -m mujoco.viewer --mjcf /home/models/ant.xml
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Detecting GPU hardware..."

# Detect GPU type and choose appropriate image
if lspci | grep -E "(AMD|ATI)" | grep -E "(VGA|Display)" > /dev/null; then
    IMAGE_NAME="gpu-sandbox:gl-amd"
    GPU_TYPE="AMD"
    echo "✓ AMD GPU detected"
elif lspci | grep -i nvidia > /dev/null; then
    IMAGE_NAME="gpu-sandbox:gl"
    GPU_TYPE="NVIDIA"
    echo "✓ NVIDIA GPU detected"
else
    IMAGE_NAME="gpu-sandbox:gl"
    GPU_TYPE="Intel/Integrated"
    echo "✓ Using integrated graphics support"
fi

# Check if image exists
if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "❌ Docker image $IMAGE_NAME not found!"
    echo ""
    echo "Please build the image first:"
    if [ "$IMAGE_NAME" = "gpu-sandbox:gl-amd" ]; then
        echo "  ./build.sh amd    # For AMD GPU support"
    else
        echo "  ./build.sh        # Standard build"
    fi
    exit 1
fi

echo "🚀 Starting container with hardware GL support..."
echo "GPU Type: $GPU_TYPE"
echo "Container: $IMAGE_NAME"
echo ""

# Check if we need NVIDIA runtime
NVIDIA_ARGS=""
if [ "$GPU_TYPE" = "NVIDIA" ] && docker info 2>/dev/null | grep -i nvidia > /dev/null; then
    echo "🔥 NVIDIA Container Runtime detected - enabling GPU support"
    NVIDIA_ARGS="--gpus all -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=all"
fi

# Start container with hardware GL support
docker run -it --rm \
    --name gl-sandbox \
    --device=/dev/dri:/dev/dri \
    --group-add video \
    -e DISPLAY=$DISPLAY \
    -e LIBGL_ALWAYS_INDIRECT=0 \
    -e LIBGL_ALWAYS_SOFTWARE=0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    --security-opt seccomp=unconfined \
    --cap-add=SYS_PTRACE \
    $NVIDIA_ARGS \
    "$IMAGE_NAME" "$@"
