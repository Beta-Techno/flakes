#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ────────────────────────────────────────────
TOOLBOX_DIR="$HOME/.local/share/flakes"
REPO_URL_HTTPS="https://github.com/Beta-Techno/flakes.git"
REPO_URL_SSH="git@github.com:Beta-Techno/flakes.git"

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

# ── Install Nix if not present ───────────────────────────────
if ! command -v nix >/dev/null 2>&1; then
  echo "+ installing Nix"
  sh <(curl -L https://nixos.org/nix/install) --daemon
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# ── Check prerequisites ──────────────────────────────────────
echo "Checking prerequisites..."
check_command nix

# ── Check Nix installation ───────────────────────────────────
if ! nix --version | grep -q "nix (Nix) 2"; then
  die "Nix 2.x is required. Please upgrade your Nix installation."
fi

# ── Install minimal git if not present ───────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "+ installing minimal git"
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    if command -v brew >/dev/null 2>&1; then
      brew install git
    else
      die "Homebrew is required to install git on macOS. Please install Homebrew first."
    fi
  else
    # Linux
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y git
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y git
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y git
    else
      die "Could not find a supported package manager to install git."
    fi
  fi
fi

# ── Check Home-Manager ───────────────────────────────────────
if ! command -v home-manager >/dev/null 2>&1; then
  echo "+ installing Home-Manager"
  nix profile install nixpkgs#home-manager
fi

# ── Clone repository ─────────────────────────────────────────
if [ ! -d "$TOOLBOX_DIR" ]; then
  echo "+ cloning repository"
  git clone https://github.com/Beta-Techno/flakes.git "$TOOLBOX_DIR"
fi

# ── Enable nix-command experimental feature ─────────────────
echo "+ enabling nix-command experimental feature"
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# ── Install CLI tools ────────────────────────────────────────
echo "+ installing CLI tools"
for tool in auth setup sync-repos doctor activate; do
  nix profile install "$TOOLBOX_DIR#${tool}"
done

# ── Set up GitHub authentication ─────────────────────────────
echo "+ setting up GitHub authentication"
if ! nix run "$TOOLBOX_DIR#auth"; then
  die "GitHub authentication failed. Please try again."
fi

# ── Switch to SSH remote ────────────────────────────────────
echo "+ switching to SSH remote"
if ! (cd "$TOOLBOX_DIR" && git remote set-url origin "$REPO_URL_SSH"); then
  die "Failed to switch to SSH remote. Please check your Git configuration."
fi

# ── Run setup ───────────────────────────────────────────────
echo "+ running setup"
if ! nix run "$TOOLBOX_DIR#setup"; then
  die "Setup failed. Please check the error messages above."
fi

echo "✅  Installation complete"
echo "Your development environment is ready!"
echo "Run 'doctor' to verify your setup." 