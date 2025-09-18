#!/bin/bash

# Entrypoint script for Docker container with Intel GPU support
# This script ensures proper permissions for GPU devices and executes the requested command

echo "Setting up Intel GPU access..."

# Ensure proper permissions for Intel GPU devices
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

# List available DRI devices for debugging
echo ""
echo "Available DRI devices:"
ls -la /dev/dri/ 2>/dev/null || echo "No /dev/dri directory found"

echo ""
echo "glxinfo:"
glxinfo -B | egrep 'OpenGL vendor|OpenGL renderer|OpenGL version'

echo ""
echo "GPU setup complete. Executing command: $@"
echo "----------------------------------------"

# Execute the requested command
exec "$@"
