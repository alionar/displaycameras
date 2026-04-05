FROM --platform=linux/arm64 vascoguita/raspios:arm64

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    # Player and IPC (matches install.sh)
    mpv \
    socat \
    wmctrl \
    # X11 utilities (xset, xdpyinfo)
    x11-utils \
    x11-xserver-utils \
    # Virtual display + VNC (tigervnc bundles X server + VNC in one)
    tigervnc-standalone-server \
    websockify \
    # Test video generation
    ffmpeg \
    # Utilities
    procps \
    cron \
    bash \
    openbox \
    python3-xdg \
    menu \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC directly from GitHub (avoids broken apt package)
RUN mkdir -p /usr/share/novnc && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
    | tar xz --strip-components=1 -C /usr/share/novnc

# Install scripts (from repo root — build context is ../)
COPY displaycameras    /usr/bin/displaycameras
COPY mpv_ipccontrol    /usr/bin/mpv_ipccontrol
COPY rotatedisplays    /usr/bin/rotatedisplays
RUN chmod 0755 /usr/bin/displaycameras /usr/bin/mpv_ipccontrol /usr/bin/rotatedisplays

# Install config
RUN mkdir -p /etc/displaycameras
COPY dev/config/displaycameras.conf       /etc/displaycameras/displaycameras.conf
COPY dev/config/layout.conf.default       /etc/displaycameras/layout.conf.default

# Openbox config — disable window decorations for mpv + disable screen blanking
RUN mkdir -p /root/.config/openbox /etc/xdg/openbox
COPY dev/config/openbox-rc.xml           /root/.config/openbox/rc.xml
RUN printf '#!/bin/sh\nxset -dpms 2>/dev/null || true\nxset s noblank 2>/dev/null || true\nxset s off 2>/dev/null || true\n' > /etc/xdg/openbox/autostart && \
    chmod +x /etc/xdg/openbox/autostart

# Generate test video (480x360 4:3 in 640x360 16:9 windows — exposes aspect ratio bugs, 60s loop)
RUN mkdir -p /test && \
    ffmpeg -f lavfi -i testsrc=size=480x360:rate=25 -t 60 /test/test.mp4 -y -loglevel quiet

# Install cron job (matches real Pi install)
COPY repaircameras.cron /etc/cron.d/repaircameras
RUN chmod 0644 /etc/cron.d/repaircameras

# Mock /boot/firmware (Bookworm path for displaydetect)
RUN mkdir -p /boot/firmware && \
    echo "disable_overscan=1" > /boot/firmware/config.txt

# PID dir
RUN mkdir -p /var/run/displaycameras

COPY dev/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080

ENTRYPOINT ["/entrypoint.sh"]
