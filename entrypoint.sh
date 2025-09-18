#!/bin/bash

# Entrypoint script for Docker container with multi-GPU support
# This script detects available GPU hardware and configures the environment accordingly

echo "=== Multi-GPU Container Setup ==="
echo "Build configuration: GPU_SUPPORT=${GPU_SUPPORT_BUILD}, CUDA=${CUDA_ENABLED}, ROCm=${ROCM_ENABLED}"

# Function to detect GPU hardware
detect_gpu() {
    local gpu_info=$(lspci | grep -E "(VGA|3D|Display)" || echo "No GPU detected")
    echo "Detected hardware:"
    echo "$gpu_info"
    
    # Check for NVIDIA dedicated GPU
    if lspci | grep -i nvidia > /dev/null; then
        echo "✓ NVIDIA dedicated GPU detected"
        GPU_TYPE="nvidia"
        return 0
    fi
    
    # Check for AMD dedicated GPU (discrete)
    if lspci | grep -E "(AMD|ATI)" | grep -E "(VGA|Display)" | grep -v "APU" > /dev/null; then
        echo "✓ AMD dedicated GPU detected"
        GPU_TYPE="amd"
        return 0
    fi
    
    # Check for integrated graphics (Intel or AMD APU)
    if lspci | grep -E "(Intel.*Graphics|AMD.*APU|Intel.*Display)" > /dev/null; then
        local gpu_name=$(lspci | grep -E "(Intel.*Graphics|AMD.*APU|Intel.*Display)" | head -1)
        echo "✓ Integrated GPU detected: $gpu_name"
        GPU_TYPE="integrated"
        return 0
    fi
    
    echo "⚠️  No recognized GPU detected, defaulting to software rendering"
    GPU_TYPE="software"
    return 1
}

# Function to configure GPU-specific settings
configure_gpu() {
    case "$GPU_TYPE" in
        "nvidia")
            echo "Configuring for NVIDIA dedicated GPU..."
            export __GL_SYNC_TO_VBLANK=1
            export __GL_SYNC_DISPLAY_DEVICE=DFP
            # Check for NVIDIA devices
            if [ -c /dev/nvidia0 ]; then
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
