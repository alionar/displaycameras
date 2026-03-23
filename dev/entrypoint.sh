#!/bin/bash
set -e

DISPLAY_NUM=:0
RESOLUTION="1920x1080x24"
VNC_PORT=5900
NOVNC_PORT=6080

echo "==> Starting Xvfb virtual display at $DISPLAY_NUM ($RESOLUTION)"
Xvfb $DISPLAY_NUM -screen 0 $RESOLUTION &
sleep 1

echo "==> Starting Openbox window manager"
DISPLAY=$DISPLAY_NUM openbox-session &
sleep 1

echo "==> Starting x11vnc"
x11vnc -display $DISPLAY_NUM -nopw -listen 0.0.0.0 -port $VNC_PORT -forever -quiet &
sleep 1

echo "==> Starting noVNC on port $NOVNC_PORT"
websockify --web /usr/share/novnc $NOVNC_PORT localhost:$VNC_PORT &
sleep 1

echo ""
echo "============================================"
echo "  Display available at:"
echo "  http://localhost:$NOVNC_PORT/vnc.html"
echo "============================================"
echo ""

export DISPLAY=$DISPLAY_NUM

# Run tests if requested
if [ "$1" = "test" ]; then
    echo "==> Running automated tests"
    bash /tests/run_tests.sh
    exit $?
fi

# Otherwise drop to shell
exec bash
