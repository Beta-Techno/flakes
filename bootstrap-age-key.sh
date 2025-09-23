#!/usr/bin/env bash
# Generate a new Age key for netbox-01
set -euo pipefail

echo "🔑 Generate NetBox Age Key"
echo "=========================="
echo ""

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if age-keygen is available
if ! command -v age-keygen &> /dev/null; then
    echo "📦 Installing age-keygen..."
    nix shell nixpkgs#age -c age-keygen --version
fi

echo "🔧 Creating sops-nix directory..."
install -d -m 0700 /var/lib/sops-nix

# Check if key already exists (created by SOPS during build)
if [ -f "/var/lib/sops-nix/key.txt" ]; then
    echo "✅ Age key already exists (created by SOPS during build)"
    echo "🔍 Using existing Age key..."
else
    echo "🔑 Generating new Age key..."
    if command -v age-keygen &> /dev/null; then
        age-keygen -o /var/lib/sops-nix/key.txt
    else
        nix shell nixpkgs#age -c age-keygen -o /var/lib/sops-nix/key.txt
    fi
    echo "✅ Age key generated successfully!"
fi
echo ""

echo "🔍 Public key (copy this for your configuration):"
if command -v age-keygen &> /dev/null; then
    age-keygen -y /var/lib/sops-nix/key.txt
else
    nix shell nixpkgs#age -c age-keygen -y /var/lib/sops-nix/key.txt
fi

echo ""
echo "📋 Next steps:"
echo "  1. Copy the 'age1...' public key above"
echo "  2. Give it to your coding agent to update the configuration"
echo "  3. The agent will re-encrypt secrets with your new key"
echo "  4. Rebuild netbox-01 with: sudo nixos-rebuild switch --flake .#netbox-01"
echo ""
echo "✅ Age key setup complete!"
