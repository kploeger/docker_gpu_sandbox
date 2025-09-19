# Docker GPU Sandbox

Simplified Docker environment for hardware OpenGL acceleration across all GPU types.

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

### NVIDIA GPUs (Per-User Rootfull Docker Daemons)
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

## Legacy Scripts (Backward Compatibility)

All legacy scripts redirect to the new unified scripts:
- `./run_gl.sh` → `./run.sh`
- `./run_auto.sh` → `./run.sh`
- `./run_nvidia.sh` → `./run.sh`
- `./run_amd.sh` → `./run.sh`
- `./run_integrated.sh` → `./run.sh`

## Features

- **Universal GPU Support** - Intel, AMD, and NVIDIA GPUs with automatic detection
- **Hardware OpenGL** - Mesa drivers for Intel/AMD, NVIDIA Container Runtime for NVIDIA
- **ROS Noetic + MuJoCo** - Ready for robotics simulation with hardware acceleration
- **Smart Building** - Fast builds by default, AMD drivers only when needed

## Troubleshooting

```bash
# Check GPU detection
lspci | grep -E "(VGA|3D|Display)"

# Check DRI devices
ls -la /dev/dri/

# Test OpenGL in container
./run.sh glxinfo | grep "Direct rendering"

# NVIDIA specific
nvidia-smi
docker info | grep nvidia

# Per-user Docker daemon troubleshooting
docker context ls                    # Check active context
echo $DOCKER_HOST                   # Should show your user daemon socket
ps aux | grep dockerd               # Check running Docker daemons
```

### Common Issues with Per-User Docker Daemons

**NVIDIA runtime not found:**
- Ensure `~/.config/docker/daemon.json` has the nvidia runtime configured
- Restart Docker daemon: `sudo stop-docker && sudo start-docker`
- Verify with: `docker info | grep -i runtime`

**Permission issues:**
- Make sure your user can access `/dev/nvidia*` devices: `ls -la /dev/nvidia*`
- Check Docker daemon is running as your user: `ps aux | grep dockerd`

**X11 forwarding issues:**
- Run `xhost +local:` before starting containers
- Verify `$DISPLAY` is set: `echo $DISPLAY`

**Docker daemon management:**
- Stop daemon: `sudo stop-docker`
- Start daemon: `sudo start-docker`
- Check status: `docker info` or `ps aux | grep dockerd`

## Prerequisites

**All Systems:** X11 forwarding enabled (`xhost +local:` or proper X auth)

**Intel/AMD GPUs:** Mesa drivers installed, `/dev/dri/*` access  
**NVIDIA GPUs:** NVIDIA drivers + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## Testing

```bash
# Inside container, test OpenGL
glxinfo | grep "OpenGL renderer"
glxinfo | grep "Direct rendering"

# Run MuJoCo simulation
cd /home/models
python3 -c "
import mujoco
import mujoco.viewer
model = mujoco.MjModel.from_xml_path('ant.xml')
data = mujoco.MjData(model)
mujoco.viewer.launch(model, data)
"
```

## Troubleshooting

```bash
# Check GPU detection
lspci | grep -E "(VGA|3D|Display)"

# Check DRI devices
ls -la /dev/dri/

# NVIDIA specific
nvidia-smi
docker info | grep nvidia
```