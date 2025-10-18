#!/usr/bin/env bash
set -Eeuo pipefail

# Bootstrap script for one-liner installation
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/Beta-Techno/flakes/main/scripts/install)"

REPO_URL="https://github.com/Beta-Techno/flakes.git"
INSTALL_PATH="/etc/nixos/flakes"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    NixOS Deployment Tool                     ║"
echo "║                                                              ║"
echo "║  Installing your development environment on NixOS           ║"
echo "║  with professional deployment tools and configurations.     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# Detect environment
if [[ -f /etc/NIXOS ]]; then
    echo "[INFO] Detected NixOS system"
    ENV="nixos"
elif [[ -f /etc/debian_version ]]; then
    echo "[INFO] Detected Debian/Ubuntu system"
    ENV="debian"
else
    echo "[ERROR] Unsupported system. This installer requires NixOS or Debian/Ubuntu."
    exit 1
fi

# Install git if needed
if ! command -v git >/dev/null 2>&1; then
    echo "[INFO] Installing git..."
    if [[ "$ENV" == "nixos" ]]; then
        nix-env -i git
    else
        sudo apt-get update && sudo apt-get install -y git
    fi
fi

# Clone repository
echo "[INFO] Cloning repository to $INSTALL_PATH..."
sudo mkdir -p "$(dirname "$INSTALL_PATH")"

if [[ -d "$INSTALL_PATH" ]]; then
    echo "[INFO] Removing existing installation..."
    sudo rm -rf "$INSTALL_PATH"
fi

if sudo git clone "$REPO_URL" "$INSTALL_PATH"; then
    echo "[SUCCESS] Repository cloned successfully"
else
    echo "[ERROR] Failed to clone repository"
    exit 1
fi

# Ensure remote URL is correct (fixes sudo clone issues)
echo "[INFO] Verifying and fixing remote URL..."
if ! sudo git -C "$INSTALL_PATH" remote get-url origin | grep -q "github.com"; then
    echo "[INFO] Fixing remote URL..."
    sudo git -C "$INSTALL_PATH" remote set-url origin "$REPO_URL"
    echo "[SUCCESS] Remote URL corrected"
else
    echo "[SUCCESS] Remote URL is correct"
fi

# Set permissions
sudo chown -R "$(whoami)" "$INSTALL_PATH"
echo "[SUCCESS] Repository permissions set"

# Make nixos-deploy executable
chmod +x "$INSTALL_PATH/scripts/nixos-deploy"

# Create symlink for easy access
if sudo mkdir -p /usr/local/bin 2>/dev/null; then
    sudo ln -sf "$INSTALL_PATH/scripts/nixos-deploy" /usr/local/bin/nixos-deploy
    echo "[SUCCESS] nixos-deploy symlinked to /usr/local/bin/nixos-deploy"
fi

echo
echo "✅ Installation complete!"
echo
echo "Next steps:"
echo "1. Run the interactive setup:"
echo "   nixos-deploy"
echo
echo "2. Or deploy directly:"
echo "   nixos-deploy nick-vm --dry-run"
echo
echo "3. Available commands:"
echo "   nixos-deploy --help"
echo
echo "Your NixOS development environment is ready! 🚀"
