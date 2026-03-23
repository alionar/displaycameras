# displaycameras

displaycameras is a set of scripts run as a service on Raspberry Pi hardware to locally display RTSP streams from IP security cameras. It displays each configured feed in a grid of windows on a locally attached display.

> **64-bit Raspberry Pi OS (Bookworm) support:** This branch (`feature/mpv-64bit`) replaces omxplayer with **mpv**, enabling full support on 64-bit ARM. omxplayer was removed from Raspberry Pi OS in Bullseye/Bookworm. See [Key Differences](#key-differences-from-omxplayer-branch) below.

## Donations
If you feel compelled to contribute to the project, feel free to send funds to https://www.paypal.me/anonymousdog

---

# Pre-requisites

* Raspberry Pi hardware
* **64-bit Raspberry Pi OS (Bookworm)** — this branch targets ARM64
* systemd init system
* Raspbian Lite is **STRONGLY** recommended
* A locally attached display (HDMI)

## Required packages

The install script handles this automatically. To install manually:

```bash
sudo apt-get install -y mpv socat xserver-xorg-core xserver-xorg xinit openbox
```

`socat` is required by `mpv_ipccontrol` to communicate with mpv's IPC socket.

## X11 requirement

mpv requires an X11 display server for multi-window output. The install script sets up a minimal X11 + openbox service automatically. To set it up manually:

```bash
# Create /etc/systemd/system/xorg.service
sudo systemctl enable xorg
sudo systemctl start xorg

# Verify
DISPLAY=:0 xdpyinfo | head -3
```

displaycameras will not start without X11 running (`Requires=xorg.service` in the unit file).

---

# Download/Install/Upgrade/Remove

## Download the Archive
### Latest Release (recommended)
Go to https://github.com/Anonymousdog/displaycameras/releases/latest and download the Source Code (tar.gz) file

### Latest Commits (only when directed)
Download https://github.com/Anonymousdog/displaycameras/archive/feature/mpv-64bit.tar.gz

## Unpack the Archive
1. `tar -xvzf ./<source_code.tar.gz>`
2. `cd ./<source_code directory>`

## Make the Installer Executable
```bash
chmod u+x ./install.sh
```

## Installation
```bash
sudo ./install.sh
```

The installer will:
- Install mpv, socat, xserver-xorg, openbox
- Copy scripts to `/usr/bin/`
- Copy config files to `/etc/displaycameras/`
- Create and enable the `xorg.service` systemd unit
- Enable the `displaycameras.service` systemd unit

## Upgrade
```bash
sudo ./install.sh upgrade
```

No changes will be made to your existing config files or cron job.

## Removal
1. Stop and disable the service:
   ```bash
   sudo systemctl stop displaycameras
   sudo systemctl disable displaycameras
   sudo systemctl stop xorg
   sudo systemctl disable xorg
   ```
2. Remove files:
   ```bash
   sudo rm -R /etc/displaycameras
   sudo rm /etc/systemd/system/displaycameras.service
   sudo rm /etc/systemd/system/xorg.service
   sudo rm /usr/bin/displaycameras /usr/bin/mpv_ipccontrol /usr/bin/rotatedisplays /usr/bin/black.png
   sudo rm /etc/cron.d/repaircameras && sudo systemctl restart cron
   ```
3. Remove packages (optional):
   ```bash
   sudo apt-get purge mpv socat -y && sudo apt-get autoremove -y
   ```

---

# CONFIGURATION

Edit `/etc/displaycameras/displaycameras.conf` and `/etc/displaycameras/layout.conf.default` for your environment.

## Minimal Configuration

### Global Options (`displaycameras.conf`)
| Variable | Description |
|----------|-------------|
| `omx_timeout` | Network timeout in seconds (default: 30) |
| `startsleep` | Seconds to wait after launching each mpv instance |
| `feedsleep` | Seconds to wait before checking feed playback position |
| `retry` | Max retries for startup and feed checks |
| `blank` | Set `"true"` to blank screen on start (uses `xset dpms`) |
| `rotate` | Set `"true"` to enable camera rotation |
| `rotatedelay` | Seconds between rotation steps |
| `displaydetect` | Set `"true"` to auto-detect display resolution |

### Camera and Window Layout (`layout.conf.default`)
- Define `windows`, `window_positions`, `camera_names`, and `camera_feeds`
- Window positions use omxplayer format `"x1 y1 x2 y2"` — converted automatically to mpv geometry

**Example (6-camera 3×2 grid on 1920×1080):**
```bash
window_positions=(
"0 0 639 359"
"640 0 1279 359"
"1280 0 1919 359"
"0 360 639 719"
"640 360 1279 719"
"1280 360 1919 719"
)
camera_names=(cam1 cam2 cam3 cam4 cam5 cam6)
camera_feeds=(
"rtsp://192.168.1.10/stream"
"rtsp://192.168.1.11/stream"
...
)
```

### Camera Name Restrictions
Camera names must be valid for use as filenames (used for PID files and IPC sockets). Stick to `[A-Za-z0-9_-]` and do not start with a digit.

---

# TESTING

## Manual test
```bash
sudo /usr/bin/displaycameras start
sudo /usr/bin/displaycameras status
sudo /usr/bin/displaycameras stop
```

Adjust `feedsleep` upward if you see playback retries. Adjust `startsleep` upward if you see startup retries.

## Developer test environment (Docker)

Test the full rewrite locally before deploying to the Pi. The `dev/` folder contains an ARM64 Docker environment with a virtual display accessible in your browser.

```bash
cd dev/
docker compose build
docker compose run --rm displaycameras-dev test
```

Open **http://localhost:6080/vnc.html** to see the virtual display.

For an interactive shell instead of running tests:
```bash
docker compose run --rm displaycameras-dev
# then inside:
displaycameras start
displaycameras status
displaycameras stop
```

To test against real cameras, edit `dev/config/layout.conf.default` and switch to the LIVE MODE block (real RTSP URLs). The container uses `network_mode: host` so it can reach cameras on your LAN.

## Debugging

### Check status of all feeds
```bash
sudo /usr/bin/displaycameras status
```

### Live dashboard (refreshes every 5s)
```bash
sudo /usr/bin/displaycameras observe
```
Shows camera name, play status, uptime, and restart count.

### View log files and restart counts
```bash
sudo /usr/bin/displaycameras logs
```

### Enable verbose mpv logging for one camera
```bash
sudo /usr/bin/displaycameras debug <camera_name> on
# view output:
tail -f /var/log/displaycameras/mpv-<camera_name>.log
# disable:
sudo /usr/bin/displaycameras debug <camera_name> off
```

### Verify mpv can play a feed directly
```bash
DISPLAY=:0 mpv --rtsp-transport=tcp --no-terminal <camera_feed_URL>
```

### Check IPC command log
```bash
tail -f /var/log/displaycameras/ipc.log
```

---

# Managing the Service

```bash
sudo systemctl start displaycameras
sudo systemctl stop displaycameras
sudo systemctl restart displaycameras
sudo systemctl status displaycameras
```

### Repair (restart failed feeds without full restart)
```bash
sudo systemctl reload displaycameras
# or directly:
sudo /usr/bin/displaycameras repair
```

---

# Advanced Configurations

## Display Detection
Enable `displaydetect="true"` in `displaycameras.conf` and create layout files named `/etc/displaycameras/layout.conf.<resolution>` (e.g., `layout.conf.1920x1080`).

## Rotation
To rotate more cameras through fewer windows, set `rotate="true"` in `displaycameras.conf` and ensure you have at least as many `window_positions` as `camera_names`.

> **Note:** mpv has no equivalent to omxplayer's `setvideopos` DBUS command. Rotation works by stopping and restarting each mpv instance at the new geometry. This is seamless for most use cases since rotation is typically infrequent.

## Display Blanking
Set `blank="true"` to blank the screen on start. Uses `xset dpms force off` (replaces `fbi` which is broken on Bookworm with KMS).

## Bookworm / KMS display notes
Raspberry Pi OS Bookworm uses full KMS (`vc4-kms-v3d`). If you see a black screen when X11 starts, add an explicit xorg config:

```bash
# /etc/X11/xorg.conf.d/99-vc4.conf
Section "Device"
    Identifier "vc4"
    Driver     "modesetting"
    Option     "AccelMethod" "glamor"
EndSection
```

To prevent screen blanking during camera display, add to `/etc/xdg/openbox/autostart`:
```bash
xset -dpms
xset s noblank
xset s off
```

---

# Key Differences from omxplayer Branch

| | omxplayer (legacy) | mpv (this branch) |
|--|--|--|
| OS support | 32-bit Buster only | 64-bit Bookworm |
| Display output | Framebuffer (no X needed) | X11 (`DISPLAY=:0`) |
| Window position | `--win "x1 y1 x2 y2"` | `--geometry=WxH+X+Y` (auto-converted) |
| Hardware decode | OpenMAX IL | `--hwdec=auto-safe` |
| Health check | DBUS via `omxplayer_dbuscontrol` | IPC socket via `mpv_ipccontrol` + socat |
| Screen blanking | `fbi` | `xset dpms` |
| Control script | `omxplayer_dbuscontrol` | `mpv_ipccontrol` |
| Logging | None | Per-camera logs + IPC log + restart counters |
| New commands | — | `observe`, `debug`, `logs` |

Config files (`displaycameras.conf`, `layout.conf.*`) are **unchanged** — no migration needed.
