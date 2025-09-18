#!/bin/bash

#!/bin/bash

# Script to run tests in the Docker container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_IMAGE="gpu-sandbox:integrated"

# Allow specifying image name
IMAGE_NAME="${GPU_IMAGE:-$DEFAULT_IMAGE}"

# Function to run a test script
run_test() {
    local test_script="$1"
    local test_name="$2"
    
    echo "========================================"
    echo "Running $test_name"
    echo "Image: $IMAGE_NAME"
    echo "========================================"
    
    # Check if image exists, if not build integrated variant
    if ! docker images | grep -q "${IMAGE_NAME%:*}"; then
        echo "Image not found, building integrated graphics variant..."
        if ! docker build -t "$DEFAULT_IMAGE" --build-arg GPU_SUPPORT=integrated "$SCRIPT_DIR"; then
            echo "❌ Failed to build Docker image"
            return 1
        fi
        IMAGE_NAME="$DEFAULT_IMAGE"
    fi
    
    docker run -it --rm \
        --device=/dev/dri:/dev/dri \
        --group-add video \
        -e DISPLAY=$DISPLAY \
        -e LIBGL_ALWAYS_INDIRECT=0 \
        -e LIBGL_ALWAYS_SOFTWARE=0 \
        -e MESA_GL_VERSION_OVERRIDE=3.3 \
        -e MESA_GLSL_VERSION_OVERRIDE=330 \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v "$SCRIPT_DIR/$test_script:/test_script.py:ro" \
        "$IMAGE_NAME" python3 /test_script.py
    
    local exit_code=$?
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ $test_name PASSED"
    else
        echo "❌ $test_name FAILED (exit code: $exit_code)"
    fi
    
    echo ""
    return $exit_code
}

# Run tests based on command line arguments
case "${1:-all}" in
    "opengl")
        run_test "test_opengl.py" "OpenGL Test"
        exit $?
        ;;
    "mujoco")
        run_test "test_mujoco.py" "MuJoCo Test"
        exit $?
        ;;
    "all"|*)
        echo "Running all tests..."
        echo ""
        
        run_test "test_opengl.py" "OpenGL Test"
        opengl_result=$?
        
        run_test "test_mujoco.py" "MuJoCo Test"
        mujoco_result=$?
        
        echo "========================================"
        echo "FINAL RESULTS"
        echo "========================================"
        echo "OpenGL Test: $([ $opengl_result -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
        echo "MuJoCo Test: $([ $mujoco_result -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
        echo ""
        
        if [ $opengl_result -eq 0 ] && [ $mujoco_result -eq 0 ]; then
            echo "🎉 All tests passed! Your setup is ready for MuJoCo with hardware rendering."
            exit 0
        else
            echo "❌ Some tests failed. Check the output above for details."
            exit 1
        fi
        ;;
esac
