# Home Assistant Integration & Security Architecture

This document describes the Home Assistant REST API integration, desktop application launchers, and Antigravity MCP server integration on this **Fedora Asahi** system.

---

## 1. Secrets & Private Configuration

To ensure absolute privacy and allow easy switching between local LAN IP addresses (e.g. `http://homeassistant.local:8123`), public domains, Tailscale URLs, or Nabu Casa endpoints without altering git-tracked files, configuration is stored outside of git in `$XDG_CONFIG_HOME/home-assistant/`.

### Setup Instructions

```bash
mkdir -p ~/.config/home-assistant

# 1. Set your Home Assistant endpoint URL:
echo "http://homeassistant.local:8123" > ~/.config/home-assistant/url

# 2. Set your Long-Lived Access Token (Profile -> Security in Home Assistant):
umask 177 && cat > ~/.config/home-assistant/token

# 3. Lock permissions:
chmod 600 ~/.config/home-assistant/url ~/.config/home-assistant/token
```

Templates are provided in the repository:
- [`dotfiles/home-assistant/.config/home-assistant/url.template`](../../home-assistant/.config/home-assistant/url.template)
- [`dotfiles/home-assistant/.config/home-assistant/token.template`](../../home-assistant/.config/home-assistant/token.template)

Git tracking explicitly ignores `**/url` and `**/token` in `.gitignore`.

---

## 2. CLI & Desktop Integration

### Entity Toggle Script (`ha-toggle`)

Located at [`dotfiles/home-assistant/.config/home-assistant/scripts/ha-toggle`](../../home-assistant/.config/home-assistant/scripts/ha-toggle) and symlinked to `~/.local/bin/ha-toggle`:

- Reads the base URL from `~/.config/home-assistant/url` (fallback to `$HA_URL`).
- Reads the bearer token from `~/.config/home-assistant/token`.
- Invokes the Home Assistant REST API endpoint `/api/services/<domain>/toggle`.
- Sends native desktop notifications via `notify-send` if an error occurs.

Usage:
```bash
ha-toggle switch.fan
ha-toggle light.studio
```

### Desktop Application Launcher (`ha-open`)

Located at [`dotfiles/home-assistant/.local/bin/ha-open`](../../home-assistant/.local/bin/ha-open) and symlinked to `~/.local/bin/ha-open`:

- Reads the private URL from `~/.config/home-assistant/url`.
- Dispatches `xdg-open "$URL"` to open your preferred browser.
- Bound to the **Home Assistant** desktop launcher entry [`theme/.local/share/applications/home-assistant.desktop`](../../theme/.local/share/applications/home-assistant.desktop).

---

## 3. Antigravity MCP Integration

Antigravity CLI and IDE pair-programming integrates with Home Assistant via the Model Context Protocol (MCP):
- **Template Configuration**: [`agy/mcp_config.json`](../../agy/mcp_config.json) (kept disabled by default to avoid token consumption).
- **Activation**:
  ```bash
  # Copy template to live agy config if not seeded:
  cp agy/mcp_config.json ~/.gemini/config/mcp_config.json

  # Substitute your real private token/secret path:
  sed -i 's#private_INSERT_TOKEN#private_<token>#' ~/.gemini/config/mcp_config.json

  # Enable server in Antigravity:
  agy mcp enable homeassistant
  ```
- The live configuration file `~/.gemini/config/mcp_config.json` is owned by Antigravity and unlinked from git, preventing accidental token leakage.
