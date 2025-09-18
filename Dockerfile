FROM ros:noetic-ros-base 

# ROS Noetic is EOL since May 2025, so the keyring used by the official ROS APT repository has expired.
# Therefore, we need to manually update the keyring to avoid EXPKEYSIG errors when running `apt-get update`.

# 1) Remove *all* existing ROS APT entries (if any)  #
#    (so apt-get update only touches Ubuntu repos)   #
# 2) Install GnuPG & dirmngr (so we can fetch keys)#
#    WITHOUT touching any ROS repo yet.            #
# 3) Fetch & dearmour the new ROS Noetic key *directly* from GitHub#
# 4) Recreate a fresh ROS APT source file that uses the new key #
#    We set “signed-by=/usr/share/keyrings/ros-archive-keyring.gpg” #
RUN rm -f /etc/apt/sources.list.d/ros-latest.list && \
    rm -f /etc/apt/sources.list.d/ros1-latest.list && \
    rm -f /etc/apt/sources.list.d/ros-archive-keyring.list && \
    rm -f /etc/apt/sources.list.d/*ros*.list || true && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        dirmngr \
        ca-certificates \
        curl \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /usr/share/keyrings && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        | gpg --dearmour \
        > /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/ros-latest.list


# Use HTTPS for Ubuntu mirrors to avoid “403 Forbidden” errors when apt tries HTTP (some mirrors block or reject HTTP/IPv6 requests).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's|http://archive.ubuntu.com/ubuntu/|https://archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu/|https://security.ubuntu.com/ubuntu/|g' /etc/apt/sources.list


# Now we can safely run apt-get update again.


# Install OpenGL libraries and runtime components (not drivers - those are on host)
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        # OpenGL runtime libraries (Mesa userspace)
        mesa-utils \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        libglx-mesa0 \
        libglu1-mesa \
        # X11 libraries for GUI support
        libxrandr2 \
        libxss1 \
        libxcursor1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxi6 \
        libxinerama1 \
        libxtst6 \
        libasound2 \
        # X11 utilities
        x11-utils \
        xauth \
        # GUI applications
        nautilus \
        # basic tools
        wget \
        git \
        curl \
        tar \
        python3 \
        nano \
        vim \
        python3-pip \
        # Build tools for potential compilation needs
        build-essential \
        cmake \
        pkg-config && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Install MuJoCo dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        libglfw3-dev \
        libglew-dev \
        libosmesa6-dev \
        patchelf \
        libxrandr2 \
        libxinerama1 \
        libxcursor1 \
        libxi6 && \
    rm -rf /var/lib/apt/lists/*

# Install MuJoCo and Python dependencies
RUN pip install --no-cache-dir \
    mujoco \
    PyOpenGL \
    PyOpenGL_accelerate \
    numpy

# Set environment variables for hardware rendering
ENV DISPLAY=:0
ENV LIBGL_ALWAYS_INDIRECT=0
ENV LIBGL_ALWAYS_SOFTWARE=0
ENV MESA_GL_VERSION_OVERRIDE=3.3
ENV MESA_GLSL_VERSION_OVERRIDE=330

# Copy and set up entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create models directory and copy MuJoCo test models
RUN mkdir -p /home/models
COPY ant.xml /home/models/ant.xml

# Set the entrypoint to setup GPU and run commands
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]


