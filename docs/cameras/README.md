# RTSP Camera Viewers

Live RTSP camera streams accessible directly as Fuzzel applications and CLI shortcuts, powered by **mpv** with low-latency streaming and Niri floating window rules.

## Cameras

| Application | Command | Stream URL | App-ID |
|---|---|---|---|
| **Yard** | `view-camera yard` | `rtsp://192.168.1.206:554/stream1` | `camera-yard` |
| **Living Room** | `view-camera living-room` | `rtsp://192.168.1.10:554/stream1` | `camera-living-room` |
| **Cameras** | `view-camera both` | Both streams stacked vertically | `cameras` |

> [!TIP]
> An automated live-view popup is also available for the Yard camera triggered by Home Assistant presence and perimetral beam sensor events. See [Yard Camera Presence Popup Notification](yard-presence-popup.md).

## Usage

- **Via Fuzzel**: Press <kbd>Mod</kbd>+<kbd>D</kbd> (or <kbd>Super</kbd>+<kbd>Space</kbd>), type **Yard**, **Living Room**, or **Cameras**, and press <kbd>Enter</kbd>.
- **Via Terminal**: Run `view-camera [yard|living-room|both]` from anywhere.

### Window Controls (Niri)

Each camera opens as a **floating window** centered on the screen:

- **Move**: Hold <kbd>Mod</kbd> and left-click drag.
- **Resize**: Hold <kbd>Mod</kbd> and right-click drag.
- **Tile**: Press <kbd>Mod</kbd>+<kbd>V</kbd> to toggle between floating and tiling.
- **Close**: Press <kbd>q</kbd> (mpv native exit) or <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd>.

---

## Architecture & Design Decisions

### 1. Runner Script (`~/.local/bin/view-camera`)

The camera streams are managed by a centralized helper script [`view-camera`](file:///home/davideresigotti/dotfiles/theme/.local/bin/view-camera) symlinked by GNU Stow into `~/.local/bin/`.

The `.desktop` launchers in `~/.local/share/applications/` invoke this script directly (`Exec=view-camera yard`, etc.). This guarantees:
- **Zero Quoting Bugs**: Fuzzel's desktop entry parser strictly enforces the FreeDesktop specification (`application.c:85: command line contains non-specification-compliant quoting`). Quotes inside inline CLI arguments (e.g. `--title="Yard"`) cause Fuzzel to reject the entry. Calling a clean runner avoids all quoting and escaping limitations.
- **Unified Configuration**: Stream URLs, MPV flags, resolutions, and video filters live in one maintainable file.

### 2. Stream Format, Audio & Apple Silicon Optimization

- **Video Codec**: Both cameras broadcast **HEVC (H.265) 2560×1440 at 25 fps** over RTSP.
- **Audio**: Enabled across all views. Yard broadcasts **PCM Mu-law** (`pcm_mulaw` 8 kHz mono) and Living Room broadcasts **PCM A-law** (`pcm_alaw` 8 kHz mono).
- **Transport (`--rtsp-transport=tcp`)**: Enforces reliable TCP transport to eliminate UDP packet loss and HEVC macroblocking/gray corruption frames on Wi-Fi.
- **Decoder (`--hwdec=no`)**: The Mesa Honeykrisp Vulkan driver on Apple Silicon (M2 Pro) does not currently expose `VK_KHR_video_decode_queue`. Forcing `--hwdec=no` avoids unnecessary driver probe timeouts and errors, relying on Apple Silicon's high-performance ARM NEON CPU cores (< 1–2% CPU load for 1440p HEVC).
- **Sync (`--video-sync=desync`)**: Live camera clocks can jitter; `desync` prevents buffer stalls.

### 3. Combined Vertical View (Cameras)

The **Cameras** view uses mpv's `--lavfi-complex` filter graph with FFmpeg's `vstack` and `amix` filters to stack both 16:9 video streams and mix both audio feeds into a single window:

```bash
mpv --lavfi-complex="[vid1][vid2]vstack[vo];[aid1][aid2]amix[ao]" \
    --external-file="rtsp://192.168.1.10:554/stream1" \
    "rtsp://192.168.1.206:554/stream1"
```

- `vid1` / `aid1` = Yard (primary input, top half video, audio input 1)
- `vid2` / `aid2` = Living Room (`--external-file`, bottom half video, audio input 2)
- Audio feeds from both cameras are concurrently mixed into PipeWire without clipping or latency penalty.

### 4. Window Sizing & Vertical Aspect Ratio

- **Single Cameras (Yard / Living Room)**: `--autofit=50%x50%` (opens a balanced 16:9 viewport, ~1008×567 on HiDPI displays with zero letterboxing).
- **Combined View (Cameras)**: `--autofit=40%x70%` (opens a vertical resolution window, ~784×882 on HiDPI displays matching the combined 8:9 aspect ratio of the two stacked 16:9 streams with zero horizontal black space).
- **Aspect Ratio Integrity**: `--force-window=immediate` was removed from the combined view so mpv waits for the `vstack` filter graph to negotiate the final 2560×2880 output dimensions before creating the Wayland surface, preventing premature 16:9 window locking.

---

## Niri Window Rules

Configured in [`~/.config/niri/config.kdl`](file:///home/davideresigotti/dotfiles/niri/.config/niri/config.kdl):

```kdl
// RTSP camera viewers: open as centered floating windows
window-rule {
    match app-id=r#"^camera-"#
    match app-id=r#"^cameras$"#
    open-floating true
}
```

Floating windows automatically center on the active output and receive Niri's rounded corners and borders.
