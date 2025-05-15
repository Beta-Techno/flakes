# Nix Home Manager Configuration

This repository contains a Nix Home Manager configuration for managing user environments on Linux/macOS systems. It's designed to be used with the stable NixOS 24.05 channel.

## Features

- Development tools (VS Code, Emacs, Neovim)
- JetBrains IDEs (DataGrip, Rider)
- Modern terminals (Ghostty, Alacritty)
- Browsers and development tools
- CLI utilities and shell configurations
- Systemd user services

## Prerequisites

- Nix package manager installed
- Flakes enabled in your Nix configuration

## Quick Start

1. Install Nix (if not already installed):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enable flakes by adding to `/etc/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

3. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nix-config.git
   cd nix-config
   ```

4. Apply the configuration:
   ```bash
   nix run home-manager/master -- init --switch --flake .#rob
   ```

## Configuration

- `flake.nix`: Main configuration file defining the flake structure
- `home/dev.nix`: User-specific configuration including packages and settings

## Customization

1. Fork this repository
2. Modify `home/dev.nix` to add/remove packages
3. Update the username and home directory in the configuration
4. Apply changes with `home-manager switch`

## License

MIT License - feel free to use and modify as needed.

# Getting Started

1. **Install Nix** (if not already):
   ```sh
   sh <(curl -L https://nixos.org/nix/install)
   ```
2. **Clone this repo and run the bootstrap/install script:**
   ```sh
   git clone <repo-url>
   cd <repo-root>
   ./install.sh
   # or
   ./init.sh
   ```
3. **Switch to your Home Manager config:**
   ```sh
   home-manager switch --flake .#<host>
   # e.g. .#macbook-air
   ```
4. **Launch Emacs:**
   ```sh
   emacs
   ```
   You should see the Doom dashboard and your custom config active.

5. **Doom Emacs Aliases:**
   - `doomsync` — Sync Doom config
   - `doomup`   — Upgrade Doom 