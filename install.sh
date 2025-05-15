#!/usr/bin/env bash
set -euo pipefail

# 0. Install curl if not present
if ! command -v curl >/dev/null 2>&1; then
  echo "[INFO] Installing curl..."
  sudo apt-get update
  sudo apt-get install -y curl
else
  echo "[INFO] curl is already installed."
fi

# 1. Install git if not present
if ! command -v git >/dev/null 2>&1; then
  echo "[INFO] Installing git..."
  sudo apt-get update
  sudo apt-get install -y git
else
  echo "[INFO] git is already installed."
fi

# 2. Install Nix if not present
if ! command -v nix >/dev/null 2>&1; then
  echo "[INFO] Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  . /etc/profile.d/nix.sh
else
  echo "[INFO] Nix is already installed."
  . /etc/profile.d/nix.sh || true
fi

# 3. Enable flakes and experimental features
mkdir -p ~/.config/nix
if ! grep -q 'experimental-features =.*flakes' ~/.config/nix/nix.conf 2>/dev/null; then
  echo "[INFO] Enabling flakes and nix-command..."
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
else
  echo "[INFO] Flakes already enabled."
fi

# 4. Clone the repo if not already present
if [ ! -d flakes ]; then
  echo "[INFO] Cloning Beta-Techno/flakes..."
  git clone https://github.com/Beta-Techno/flakes.git
else
  echo "[INFO] flakes directory already exists. Skipping clone."
fi
cd flakes

# 5. Run the bootstrap script
if [ $# -gt 0 ]; then
  echo "[INFO] Running bootstrap with user: $1"
  nix run .#bootstrap -- --user "$1"
else
  echo "[INFO] Running bootstrap with current user."
  nix run .#bootstrap
fi
