#!/bin/bash

# Entrypoint script for Docker container with hardware GL support

echo "=== Hardware GL Container Setup ==="

# Function to detect GPU hardware
detect_gpu() {
    local gpu_info=$(lspci | grep -E "(VGA|3D|Display)" 2>/dev/null || echo "No GPU detected")
    echo "Detected hardware:"
    echo "$gpu_info"
    
    # Check for NVIDIA dedicated GPU
    if lspci | grep -i nvidia > /dev/null; then
        echo "✓ NVIDIA GPU detected"
        GPU_TYPE="nvidia"
        return 0
    fi
    
    # Check for AMD dedicated GPU
    if lspci | grep -E "(AMD|ATI)" | grep -E "(VGA|Display)" > /dev/null; then
        echo "✓ AMD GPU detected"
        GPU_TYPE="amd"
        return 0
    fi
    
    # Check for Intel integrated graphics (any Intel VGA device)
    if lspci | grep -i "intel" | grep -i "vga" > /dev/null; then
        echo "✓ Intel integrated graphics detected"
        GPU_TYPE="intel"
        return 0
    fi
    
    echo "⚠️  No recognized GPU detected, using software rendering"
    GPU_TYPE="software"
    return 1
}

# Function to configure OpenGL settings
configure_gl() {
    echo "Configuring OpenGL settings for: $GPU_TYPE"
    
    case "$GPU_TYPE" in
        "nvidia")
            echo "Setting up NVIDIA OpenGL..."
            export __GL_SYNC_TO_VBLANK=1
            if [ -c /dev/nvidia0 ]; then
                echo "✓ NVIDIA device nodes found"
            else
                echo "⚠️  NVIDIA devices not accessible, falling back to Mesa"
            fi
            ;;
        "amd")
            echo "Setting up AMD OpenGL..."
            export MESA_GL_VERSION_OVERRIDE=3.3
            export MESA_GLSL_VERSION_OVERRIDE=330
            ;;
        "intel")
            echo "Setting up Intel OpenGL..."
            export MESA_GL_VERSION_OVERRIDE=3.3
            export MESA_GLSL_VERSION_OVERRIDE=330
            ;;
        "software")
            echo "Setting up software rendering..."
            export LIBGL_ALWAYS_SOFTWARE=1
            export MESA_GL_VERSION_OVERRIDE=3.3
            export MESA_GLSL_VERSION_OVERRIDE=330
            ;;
    esac
    
    # Common OpenGL settings
    export LIBGL_ALWAYS_INDIRECT=0
    
    # Verify DRI devices
    if [ -d "/dev/dri" ] && [ "$(ls -A /dev/dri)" ]; then
        echo "✓ DRI devices available:"
        ls /dev/dri
    else
        echo "⚠️  No DRI devices found - hardware acceleration may not work"
    fi
}

# Function to test OpenGL setup
test_gl() {
    echo ""
    echo "Testing OpenGL setup..."
    if command -v glxinfo > /dev/null; then
        echo "OpenGL renderer: $(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "Unknown")"
        echo "OpenGL version: $(glxinfo | grep "OpenGL version" | cut -d: -f2 | xargs || echo "Unknown")"
    else
        echo "glxinfo not available for testing"
    fi
}

# Main setup
detect_gpu
configure_gl
test_gl

echo ""
echo "Container ready! GPU type: $GPU_TYPE"
echo "=========================================="
echo ""

# Execute the provided command or start bash
exec "$@"
