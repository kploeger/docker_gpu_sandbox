#!/bin/bash

# Script to build all GPU variant images

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔨 Building all GPU variant images..."
echo ""

# Function to build an image variant
build_variant() {
    local variant="$1"
    local args="$2"
    local image_name="gpu-sandbox:$variant"
    
    echo "Building $variant variant..."
    echo "Image: $image_name"
    echo "Args: $args"
    
    if docker build -t "$image_name" $args "$SCRIPT_DIR"; then
        echo "✅ Successfully built $image_name"
    else
        echo "❌ Failed to build $image_name"
        return 1
    fi
    echo ""
}

# Build variants based on arguments
case "${1:-all}" in
    "integrated")
        build_variant "integrated" "--build-arg GPU_SUPPORT=integrated"
        ;;
    "nvidia")
        build_variant "nvidia" "--build-arg GPU_SUPPORT=nvidia --build-arg ENABLE_CUDA=true"
        ;;
    "amd")
        build_variant "amd" "--build-arg GPU_SUPPORT=amd --build-arg ENABLE_ROCM=true"
        ;;
    "universal")
        build_variant "universal" "--build-arg GPU_SUPPORT=all --build-arg ENABLE_CUDA=true --build-arg ENABLE_ROCM=true"
        ;;
    "all")
        echo "Building all variants..."
        echo ""
        
        build_variant "integrated" "--build-arg GPU_SUPPORT=integrated" && \
        build_variant "nvidia" "--build-arg GPU_SUPPORT=nvidia --build-arg ENABLE_CUDA=true" && \
        build_variant "amd" "--build-arg GPU_SUPPORT=amd --build-arg ENABLE_ROCM=true" && \
        build_variant "universal" "--build-arg GPU_SUPPORT=all --build-arg ENABLE_CUDA=true --build-arg ENABLE_ROCM=true"
        
        if [ $? -eq 0 ]; then
            echo "🎉 All variants built successfully!"
        else
            echo "❌ Some builds failed"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [integrated|nvidia|amd|universal|all]"
        echo ""
        echo "Variants:"
        echo "  integrated - Intel/AMD integrated graphics only"
        echo "  nvidia     - NVIDIA dedicated GPU with CUDA support"
        echo "  amd        - AMD dedicated GPU with ROCm support"
        echo "  universal  - All GPU types supported (larger image)"
        echo "  all        - Build all variants (default)"
        exit 1
        ;;
esac

echo "Image sizes:"
docker images | grep "gpu-sandbox" | sort
