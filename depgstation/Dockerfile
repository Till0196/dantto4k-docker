FROM ghcr.io/till0196/depgstation:base AS base

ARG TARGETARCH
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
        ca-certificates \
        curl \
        gpg \
        lsb-release \
        tzdata && \
    curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/debian-jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/master/debian $(lsb_release -c -s) main" > /etc/apt/sources.list.d/jellyfin.list && \
    if [ "$TARGETARCH" = "amd64" ]; then \
        echo "deb http://cdn.debian.net/debian stable main contrib non-free" >> /etc/apt/sources.list; \
    fi && \
    # Add Raspberry Pi repository for ARM architectures
    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "arm" ]; then \
        curl -fsSL https://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/raspberrypi.gpg && \
        echo "deb [arch=$(dpkg --print-architecture)] https://archive.raspberrypi.org/debian $(lsb_release -c -s) main" >> /etc/apt/sources.list; \
    fi && \
    apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install architecture-specific packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        jellyfin-ffmpeg7 && \
    # Install Intel/AMD specific drivers for amd64/x86_64
    if [ "$TARGETARCH" = "amd64" ]; then \
        apt-get install -y --no-install-recommends \
            i965-va-driver-shaders \
            intel-media-va-driver-non-free \
            mesa-va-drivers \
            intel-opencl-icd; \
    fi && \
    # Install ARM/Raspberry Pi specific packages for arm64/arm
    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "arm" ]; then \
        apt-get install -y --no-install-recommends \
            sqlite3-pcre \
            libomxil-bellagio0 \
            libomxil-bellagio-bin \
            libraspberrypi0; \
    fi && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/local/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/local/bin/ffprobe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* ~/.npm

EXPOSE 8888
EXPOSE 8889
