# System & Dotfiles Documentation Index

Welcome to the central documentation hub for this dotfiles environment. All architectural guides, hardware tuning manuals, automation designs, and application configurations are indexed below.

---

## Table of Contents

1. [Battery & Power Optimization Architecture](#1-battery--power-optimization-architecture)
2. [RTSP Camera Feeds & Presence Automations](#2-rtsp-camera-feeds--presence-automations)
3. [Neovim Configuration & Developer Environment](#3-neovim-configuration--developer-environment)
4. [Desktop & Window Management (Niri)](#4-desktop--window-management-niri)
5. [Dotfiles & Machine Setup](#5-dotfiles--machine-setup)
6. [System Organization & Antigravity Automation](#6-system-organization--antigravity-automation)

---

## 1. Battery & Power Optimization Architecture

Tailored specifically for Apple Silicon (M2 Pro) running Fedora Asahi Remix Linux to maximize battery life while maintaining peak AC responsiveness:

- [**Battery & Power Overview**](battery-optimization/README.md): High-level system architecture, AC vs. Battery switching matrix, and power subsystems.
- [**Wallpaper Power Optimization**](battery-optimization/wallpaper.md): Dynamic switching between live 60fps video (`mpvpaper-bin`) on AC and zero-CPU static rendering (`swaybg`) on battery.
- [**Display & Keyboard ALS Automation**](battery-optimization/display-and-keyboard.md): Apple Always-On Processor (`aop-sensors-als`) integration, dual-profile machine learning brightness curves, and cubic Hermite keyboard backlight fading.
- [**Hardware & System-Level Power Tuning**](battery-optimization/system-level.md): PCIe ASPM power policies, SD card controller power management, TuneD profiles, and Akonadi/MySQL automated suspension.

---

## 2. RTSP Camera Feeds & Presence Automations

Integrated surveillance feeds and real-time smart home video notifications:

- [**RTSP Camera Viewers**](cameras/README.md): Low-latency live streams via `mpv`, multi-stream stacked layout with PipeWire audio mixing, Apple Silicon ARM NEON decode optimizations, and floating Niri window controls.
- [**Yard Camera Presence Popup Notification**](cameras/yard-presence-popup.md): Automated live-view video notification daemon triggered by Home Assistant and Mosquitto MQTT when occupancy or perimetral beam sensor events occur, with click-to-expand controls.

---

## 3. Neovim Configuration & Developer Environment

Modular, fast Neovim environment built on lazy.nvim with full language server protocol support:

- [**Neovim Setup Guide**](../nvim/.config/nvim/docs/README.md): Neovim installation, system dependencies, LSP servers, and plugin bootstrapping.
- [**Neovim Resources & Best Practices**](../nvim/.config/nvim/docs/nvim_resources.md): Curated documentation and learning materials for mastering Neovim and Lua plugins.

---

## 4. Desktop & Window Management (Niri)

- **Compositor Configuration**: [`niri/.config/niri/config.kdl`](../niri/.config/niri/config.kdl)
- **Shortcuts & Details Menu**: Press <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>/</kbd> to open the system menu (managed by [`system-menu.sh`](../niri/.config/niri/scripts/system-menu.sh)), which includes live status monitors and an interactive documentation browser.
- [**Dynamic Color & Theming Architecture**](theming/README.md): Centralized wallpaper-driven palette engine, live Pywalfox Firefox styling, and instant theme switching across Ghostty, Waybar, Fuzzel, and GTK.

---

## 5. Smart Home & Home Assistant Integration

- [**Home Assistant Integration & Security Architecture**](home-assistant/README.md): Secure private URL and token management, entity toggling (`ha-toggle`), desktop launcher (`ha-open`), and Antigravity AI pair-programming MCP integration.

---

## 6. Dotfiles & Machine Setup

- [**Main Dotfiles README**](../README.md): GNU Stow package map, quick restore instructions, and keybinding cheat sheet.
- **Installer Script**: [`install.sh`](../install.sh) for one-step bootstrapping on a fresh installation.

---

## 7. System Organization & Antigravity Automation

- [**System Organization Architecture**](system-organization/README.md): Comprehensive guide on XDG Base Directory standards, GNU Stow package conventions, collision prevention, and the Antigravity `system-organizer` AI skill.
- **Antigravity AI Skill**: Located in [`agy/skills/system-organizer/`](../agy/skills/system-organizer/SKILL.md) with automated system health auditing, package adoption, and pre-commit hygiene scripts.
- **Workspace Rule**: Enforced by [`shell/AGENTS.md`](../shell/AGENTS.md) for strict XDG compliance on every agent prompt.

