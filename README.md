# dotfiles

My Niri-on-Fedora setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow *package* mirroring `$HOME`: running `stow niri`
symlinks `~/.config/niri` to `niri/.config/niri` inside this repo. You edit the real
files as usual; every change is a git change. No copying, no sync step.
(`keyd` and `wallpapers` are the exceptions: they're copied, not symlinked — `keyd`
targets root-owned `/etc/keyd`, so `install.sh` needs sudo for it.)

## Packages

| Package      | Symlinks to `$HOME` | Contents |
|--------------|---------------------|----------|
| `niri`       | `~/.config/niri`    | `config.kdl` (portable `$HOME` spawn paths), `scripts/` (theme apply + early-dark arming, wallpaper cycling) |
| `waybar`     | `~/.config/waybar`  | `config.jsonc`, `style.css` |
| `mako`       | `~/.config/mako`    | notification daemon |
| `fuzzel`     | `~/.config/fuzzel`  | launcher used by the clipboard picker |
| `ghostty`    | `~/.config/ghostty` | terminal config (`config`) |
| `gtk-3.0`, `gtk-4.0` | `~/.config/gtk-{3,4}.0` | GTK theming + window-button assets (generated `*dank-colors.css` excluded) |
| `xsettingsd` | `~/.config/xsettingsd` | GTK settings bridge |
| `fontconfig` | `~/.config/fontconfig` | font aliases (Nerd Font -> Cascadia Code NF) |
| `darkman`    | `~/.config/darkman`, `~/.local/share/darkman` | darkman config (fixed Milan coords) + transition hook |
| `xdg-desktop-portal` | `~/.config/xdg-desktop-portal` | prefer `darkman` as the Settings portal |
| `theme`     | `~/.local/share/applications/*.desktop`, `~/.local/share/icons/hicolor` | "Theme" launcher (`darkman toggle`, sun/moon icons) + Home Assistant dashboards/toggles (HA, Proxmox, Pi-hole, Immich, Frigate, Homepage, Fan, Studio) + their icons |
| `home-assistant` | `~/.config/home-assistant/scripts` | `ha-toggle <entity>` — toggles a HA entity via the local REST API (token read from `~/.config/home-assistant/token`) |
| `autostart`  | `~/.config/autostart` | XWayland video bridge |
| `shell`      | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig` | trimmed, machine-agnostic |
| `wallpapers` | copied to `~/Pictures/Wallpapers` | JPEGs used by `wallpaper-cycle` |
| `waypaper`   | `~/.config/waypaper` | wallpaper manager config and rotate/cycle scripts |
| `tmux`       | `~/.config/tmux`     | tmux config (vi mode, keybindings, true color) |
| `nvim`       | `~/.config/nvim`     | Neovim configuration (Lazy, LSP, diagnostics) |
| `yazi`       | `~/.config/yazi`     | terminal file manager config and plugins |
| `keyd`      | copied to `/etc/keyd` (needs root) | keyboard remap: capslock->ctrl/esc |

## Restore on a new machine (Fedora)

```sh
# Packages
sudo dnf install niri waybar mako fuzzel swaybg wtype wl-clipboard \
  at xsettingsd fontconfig solaar ghostty python3-astral stow darkman

# Clipboard history (optional): cliphist + niri-copy-paste (own repo)

git clone https://github.com/Davide-Resigotti/dotfiles.git
cd dotfiles
./install.sh
```

Enable user services (logged into the graphical session):

```sh
systemctl --user enable --now darkman.service
systemctl --user enable waybar.service
```

Home Assistant toggles need a token after restore (never committed):

```sh
mkdir -p ~/.config/home-assistant
# paste a long-lived access token from HA (Profile -> Security -> Long-lived access tokens)
umask 177 && cat > ~/.config/home-assistant/token
```

The HA base URL is in `~/.config/home-assistant/scripts/ha-toggle`; the
dashboards' URLs are hardcoded in the `.desktop` files under the `theme`
package — edit them for your network. The Fan/Studio entries call the bare
`ha-toggle` name, so keep `~/.local/bin` (symlinked by `install.sh`) on PATH.

Themes: darkman is the authority — it turns on dark mode at sundown and light
again at sunrise. On top of that, `niri/.../scripts/schedule-early-dark` arms
a one-shot `at(1)` job that runs `darkman set dark` a full hour **before**
sunset. `apply-theme` does the actual GTK/niri switch; edit lat/lon + timezone
in `schedule-early-dark` (and `~/.config/darkman/config.yaml`) for your
location.

## Day-to-day

Because live paths are symlinks into this repo, just commit:

```sh
cd ~/dotfiles
git add -A && git commit -m "tweak" && git push
```

## Machine-specific notes

- `config.kdl` is portable: hardcoded `/home/<user>` paths are gone. The external
  monitor output block is commented out — uncomment and adapt the name/mode/position
  (get them from `niri msg outputs`).
- `xsettingsd` DPI (`Gdk/UnscaledDPI`) is display-specific — adjust after restore.
- Excluded on purpose: `~/.ssh`, `~/.config/gh` (tokens), `.cache`, `.local/state`,
  bash history, `node_modules`, screenshots, `*.mp4` wallpapers, and the compiled
  `niri-copy-paste` binary (built from its own repository).
