# dotfiles

My Niri-on-Fedora setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow *package* mirroring `$HOME`: running `stow niri`
symlinks `~/.config/niri` to `niri/.config/niri` inside this repo. You edit the real
files as usual; every change is a git change. No copying, no sync step.

## Packages

| Package      | Symlinks to `$HOME` | Contents |
|--------------|---------------------|----------|
| `niri`       | `~/.config/niri`    | `config.kdl` (portable `$HOME` spawn paths), `scripts/` (theme scheduling, wallpaper cycling) |
| `waybar`     | `~/.config/waybar`  | `config.jsonc`, `style.css` |
| `mako`       | `~/.config/mako`    | notification daemon |
| `fuzzel`     | `~/.config/fuzzel`  | launcher used by the clipboard picker |
| `ghostty`    | `~/.config/ghostty` | terminal config (`config`) |
| `gtk-3.0`, `gtk-4.0` | `~/.config/gtk-{3,4}.0` | GTK theming + window-button assets (generated `*dank-colors.css` excluded) |
| `xsettingsd` | `~/.config/xsettingsd` | GTK settings bridge |
| `fontconfig` | `~/.config/fontconfig` | font aliases (Nerd Font -> Cascadia Code NF) |
| `systemd`    | `~/.config/systemd/user` | `theme-scheduler.{service,timer}` |
| `autostart`  | `~/.config/autostart` | XWayland video bridge |
| `shell`      | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig` | trimmed, machine-agnostic |
| `wallpapers` | copied to `~/Pictures/Wallpapers` | JPEGs used by `wallpaper-cycle` |

## Restore on a new machine (Fedora)

```sh
# Packages
sudo dnf install niri waybar mako fuzzel swaybg wtype wl-clipboard \
  at xsettingsd fontconfig solaar ghostty python3-astral stow

# Clipboard history (optional): cliphist + niri-copy-paste (own repo)

git clone https://github.com/Davide-Resigotti/dotfiles.git
cd dotfiles
./install.sh
```

Enable user services (logged into the graphical session):

```sh
systemctl --user enable --now theme-scheduler.timer
systemctl --user enable waybar.service
```

Theme scheduling runs `at(1)` one-shot jobs — edit lat/lon + timezone in
`niri/.config/niri/scripts/schedule-theme-transitions` for your location.

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
