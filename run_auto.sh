#!/bin/bash

# Script to auto-detect GPU type and run appropriate container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Auto-detecting GPU hardware..."

# Function to detect GPU type
detect_gpu_type() {
    # Check for NVIDIA dedicated GPU
    if lspci | grep -i nvidia > /dev/null; then
        echo "✓ NVIDIA dedicated GPU detected"
        GPU_TYPE="nvidia"
        return 0
    fi
    
    # Check for AMD dedicated GPU (discrete, not APU)
    if lspci | grep -E "(AMD|ATI)" | grep -E "(VGA|Display)" | grep -v "APU" > /dev/null; then
        echo "✓ AMD dedicated GPU detected"
        GPU_TYPE="amd"
        return 0
    fi
    
    # Check for integrated graphics (Intel or AMD APU)
    if lspci | grep -E "(Intel.*Graphics|AMD.*APU|Intel.*Display)" > /dev/null; then
        local gpu_name=$(lspci | grep -E "(Intel.*Graphics|AMD.*APU|Intel.*Display)" | head -1)
        echo "✓ Integrated graphics detected: $gpu_name"
        GPU_TYPE="integrated"
        return 0
    fi
    
    echo "⚠️  No recognized GPU detected"
    echo "Available GPUs:"
    lspci | grep -E "(VGA|3D|Display)" || echo "  No GPU hardware found"
    
    GPU_TYPE="unknown"
    return 1
}

# Detect GPU and run appropriate script
detect_gpu_type

case "$GPU_TYPE" in
    "nvidia")
        echo ""
        echo "🚀 Launching NVIDIA container..."
        exec "$SCRIPT_DIR/run_nvidia.sh" "$@"
        ;;
    "amd")
        echo ""
        echo "🚀 Launching AMD dedicated GPU container..."
        exec "$SCRIPT_DIR/run_amd.sh" "$@"
        ;;
    "integrated")
        echo ""
        echo "🚀 Launching integrated graphics container..."
        exec "$SCRIPT_DIR/run_integrated.sh" "$@"
        ;;
    *)
        echo ""
        echo "❌ Cannot auto-detect GPU type. Please run manually:"
        echo "  ./run_nvidia.sh      - For NVIDIA dedicated GPUs"
        echo "  ./run_amd.sh         - For AMD dedicated GPUs"
        echo "  ./run_integrated.sh  - For Intel/AMD integrated graphics"
        exit 1
        ;;
esac
