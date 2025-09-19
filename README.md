# Docker GPU Sandbox

Simplified Docker environment for hardware OpenGL acceleration across all GPU types.

Tested for Intel/AMD integrated graphics, NVIDIA dedicated GPUs. Not tested for AMD. Not tested for Windows/Mac hosts.

## Host Setup

### Intel/AMD Integrated Graphics
```bash
# Enable X11 forwarding
xhost +local:

# Ensure DRI devices are accessible
ls /dev/dri/  # Should show card0, renderD128, etc.
```

### NVIDIA GPUs (Standard System Docker)
```bash
# Install NVIDIA Container Toolkit (Ubuntu/Debian)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Enable X11 forwarding
xhost +local:

# Verify setup
nvidia-smi
docker info | grep nvidia
# Expected output: "Runtimes: runc io.containerd.runc.v2 nvidia"
```

### NVIDIA GPUs (Per-User Rootfull Docker Daemons as in IAS WAM cell)
Designed to work with
[this setup](https://github.com/kploeger/rootfull_per_user_docker_daemons).

```bash
# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit

# Configure per-user daemon (create user-specific config)
mkdir -p ~/.config/docker
cat > ~/.config/docker/daemon.json << EOF
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
EOF

# Restart your user's Docker daemon using system scripts
sudo stop-docker
sudo start-docker

# Enable X11 forwarding
xhost +local:

# Verify setup
nvidia-smi
docker info | grep nvidia
# Expected output: "Runtimes: runc io.containerd.runc.v2 nvidia"
```

### AMD Dedicated GPUs
```bash
# Install Mesa drivers and enable DRI
sudo apt install mesa-utils mesa-vdpau-drivers

# Enable X11 forwarding
xhost +local:

# Ensure DRI/KFD devices are accessible
ls /dev/dri/  # Should show card0, renderD128, etc.
ls /dev/kfd   # For compute workloads (optional)
```

## Quick Start

```bash
# 1. Build the image
./build.sh                # Fast build (Intel/NVIDIA)
./build.sh amd            # With AMD GPU drivers (slower)

# 2. Run container (auto-detects GPU type)
./run.sh                  # Interactive session
./run.sh glxinfo          # Test OpenGL
./run.sh python3 script.py # Run custom command

# 3. Test the setup
./run_tests.sh            # Comprehensive OpenGL tests

# 4. Run MuJoCo viewer with included ant model
./run.sh python3 -m mujoco.viewer --mjcf /home/models/ant.xml
```