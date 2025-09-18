# Docker GPU Sandbox

Docker environment for GPU-accelerated applications with automatic GPU detection and multi-vendor support.

## Supported GPU Types

- **`integrated`** - Intel Iris, AMD integrated graphics
- **`nvidia`** - NVIDIA dedicated GPUs with CUDA
- **`amd`** - AMD dedicated GPUs with ROCm
- **`software`** - CPU fallback rendering

## Quick Start

```bash
# Auto-detect GPU and run
./run_auto.sh

# Manual GPU selection
./run_integrated.sh  # Intel/AMD integrated
./run_nvidia.sh      # NVIDIA dedicated
./run_amd.sh         # AMD dedicated

# Build images
./build_all.sh       # All variants
./build_all.sh integrated  # Specific type

# Test GPU acceleration
./run_tests.sh
```

## Prerequisites

**Integrated Graphics:** Mesa drivers, `/dev/dri/*` access  
**NVIDIA:** NVIDIA drivers, [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)  
**AMD:** AMD drivers, `/dev/dri/*` and `/dev/kfd` access

## Features

- ROS Noetic + MuJoCo 3.2.3
- Hardware OpenGL acceleration
- Automatic GPU detection
- Performance testing (300-1000+ FPS expected)

## Troubleshooting

```bash
# Debug mode
DEBUG=1 ./run_auto.sh

# Check GPU acceleration
glxinfo | grep "Direct rendering"
ls -la /dev/dri/
```

Common issues: Missing drivers, device permissions, nvidia-container-toolkit setup.