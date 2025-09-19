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
    
    # Check for Intel integrated graphics
    if lspci | grep -E "(Intel.*Graphics|Intel.*Display)" > /dev/null; then
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
                echo "Found NVIDIA device: /dev/nvidia0"
                chmod 666 /dev/nvidia* 2>/dev/null || true
                chmod 666 /dev/nvidiactl 2>/dev/null || true
                chmod 666 /dev/nvidia-uvm* 2>/dev/null || true
            fi
            ;;
        "amd")
            echo "Configuring for AMD dedicated GPU..."
            export RADV_PERFTEST=aco
            export AMD_VULKAN_ICD=RADV
            export ROC_ENABLE_PRE_VEGA=1
            # Configure DRI devices + ROCm devices
            configure_dri_devices
            configure_rocm_devices
            ;;
        "integrated")
            echo "Configuring for integrated graphics (Intel/AMD APU)..."
            export LIBVA_DRIVER_NAME=iHD
            export MESA_LOADER_DRIVER_OVERRIDE=iris
            # Configure DRI devices (same for Intel and AMD integrated)
            configure_dri_devices
            ;;
        "software")
            echo "Configuring for software rendering..."
            export LIBGL_ALWAYS_SOFTWARE=1
            export GALLIUM_DRIVER=llvmpipe
            export MESA_GL_VERSION_OVERRIDE=3.3
            ;;
    esac
}

# Function to configure DRI devices (integrated graphics: Intel/AMD APU)
configure_dri_devices() {
    if [ -c /dev/dri/renderD128 ]; then
        echo "Found render device: /dev/dri/renderD128"
        chmod 666 /dev/dri/renderD128
        echo "Set permissions for /dev/dri/renderD128"
    fi

    if [ -c /dev/dri/card0 ]; then
        echo "Found card device: /dev/dri/card0"
        chmod 666 /dev/dri/card0
        echo "Set permissions for /dev/dri/card0"
    fi
    
    # Handle multiple cards
    for card in /dev/dri/card*; do
        if [ -c "$card" ]; then
            chmod 666 "$card" 2>/dev/null || true
        fi
    done
}

# Function to configure ROCm devices (AMD dedicated GPUs)
configure_rocm_devices() {
    if [ -c /dev/kfd ]; then
        echo "Found ROCm KFD device: /dev/kfd"
        chmod 666 /dev/kfd
        echo "Set permissions for /dev/kfd"
    fi
    
    # Configure ROCm environment
    export HSA_OVERRIDE_GFX_VERSION=10.3.0
    export HIP_VISIBLE_DEVICES=0
}

# Main setup process
echo ""
detect_gpu
echo ""
configure_gpu
echo ""

# List available devices for debugging
echo "Available GPU devices:"
if [ -d /dev/dri ]; then
    echo "DRI devices:"
    ls -la /dev/dri/ 2>/dev/null || echo "  No DRI devices found"
fi

if ls /dev/nvidia* > /dev/null 2>&1; then
    echo "NVIDIA devices:"
    ls -la /dev/nvidia* 2>/dev/null
fi

echo ""
echo "OpenGL information:"
glxinfo -B 2>/dev/null | grep -E "(OpenGL vendor|OpenGL renderer|OpenGL version)" || echo "  Could not query OpenGL info"

echo ""
echo "Environment configured for: $GPU_TYPE GPU"
echo "Executing command: $@"
echo "=========================================="

# Execute the requested command
exec "$@"
