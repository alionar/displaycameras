FROM --platform=linux/arm64 vascoguita/raspios:arm64

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    # Player and IPC
    mpv \
    socat \
    # Virtual display + VNC (tigervnc bundles X server + VNC in one)
    tigervnc-standalone-server \
    websockify \
    # Test video generation
    ffmpeg \
    # Utilities
    procps \
    cron \
    bash \
    x11-utils \
    openbox \
    python3-xdg \
    menu \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC directly from GitHub (avoids broken apt package)
RUN mkdir -p /usr/share/novnc && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
    | tar xz --strip-components=1 -C /usr/share/novnc

# Install scripts
COPY scripts/displaycameras    /usr/bin/displaycameras
COPY scripts/mpv_ipccontrol    /usr/bin/mpv_ipccontrol
COPY scripts/rotatedisplays    /usr/bin/rotatedisplays
RUN chmod 0755 /usr/bin/displaycameras /usr/bin/mpv_ipccontrol /usr/bin/rotatedisplays

# Install config
RUN mkdir -p /etc/displaycameras
COPY config/displaycameras.conf       /etc/displaycameras/displaycameras.conf
COPY config/layout.conf.default       /etc/displaycameras/layout.conf.default

# Generate test video (640x360 color bars, 1 hour loop)
RUN mkdir -p /test && \
    ffmpeg -f lavfi -i testsrc=size=640x360:rate=25 -t 60 /test/test.mp4 -y -loglevel quiet

# PID dir
RUN mkdir -p /var/run/displaycameras

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080

ENTRYPOINT ["/entrypoint.sh"]
