#!/usr/bin/env bash
set -euo pipefail

# Instructions for the user
echo "This script will set up your Nix environment on your MacBook."
echo "Please make sure you have:"
echo "1. A working internet connection"
echo "2. Sudo privileges"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

echo "→ Installing Nix..."
if ! command -v nix >/dev/null 2>&1; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
    # Source nix for the current shell
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "→ Enabling flakes..."
if ! grep -q "experimental-features = nix-command flakes" /etc/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
fi

echo "→ Allow unprivileged user-namespaces (needed by Chrome/Electron)..."
sudo tee /etc/sysctl.d/60-apparmor-userns.conf >/dev/null <<'EOF'
# Allow Chrome/Electron and other user-namespace tools to run without extra AppArmor rules
kernel.apparmor_restrict_unprivileged_userns = 0
EOF

# Apply immediately without reboot
sudo systemctl restart systemd-sysctl.service 2>/dev/null || sudo sysctl -p /etc/sysctl.d/60-apparmor-userns.conf

echo "→ Installing Home Manager..."
nix run github:nix-community/home-manager/release-24.05 -- init --switch

echo "→ Applying configuration..."
nix run github:Beta-Techno/flakes#bootstrap --no-write-lock-file

echo "✓ Installation complete!"
echo "Please:"
echo "1. Restart your terminal"
echo "2. Log out and back in for all changes to take effect" 