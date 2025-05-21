#!/usr/bin/env bash
set -euo pipefail

# Re-connect all three FDs if we still have a terminal
if ! [ -t 0 ] && [ -e /dev/tty ]; then
  exec </dev/tty >/dev/tty 2>&1
fi

# ── Helper functions ─────────────────────────────────────────
die() {
  echo "Error: $1" >&2
  exit 1
}

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "$1 is not installed. Please install it first."
  fi
}

# ── Install curl if not present ───────────────────────────────
if ! command -v curl >/dev/null 2>&1; then
  echo "+ installing curl..."
  sudo apt-get update
  sudo apt-get install -y curl
fi

# ── Install Nix if not present ───────────────────────────────
if ! command -v nix >/dev/null 2>&1; then
  echo "+ installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  . /etc/profile.d/nix.sh
fi

# ── Install git if not present ───────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "+ installing git..."
  sudo apt-get update
  sudo apt-get install -y git
fi

# ── Enable flakes and experimental features ─────────────────
echo "+ enabling flakes and nix-command..."
mkdir -p ~/.config/nix
if ! grep -q 'experimental-features =.*flakes' ~/.config/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# ── Clone the repository if not present ─────────────────────
REPO_DIR="$HOME/flakes"
if [ ! -d "$REPO_DIR" ]; then
  echo "+ cloning repository..."
  git clone https://github.com/Beta-Techno/flakes.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# ── Run the bootstrap process ───────────────────────────────
echo "+ running bootstrap process..."

# 1. Authenticate with GitHub
echo "▶ Authenticating with GitHub..."
nix run .#auth

# 2. Set up development environment
echo "▶ Setting up development environment..."
nix run .#setup

# 3. Activate the configuration
echo "▶ Activating configuration..."
nix run .#activate

# 4. Sync repositories
echo "▶ Syncing repositories..."
nix run .#sync-repos

echo "✅  Installation complete! Your development environment is ready." 