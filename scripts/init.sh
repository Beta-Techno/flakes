#!/usr/bin/env bash
set -euo pipefail

echo "→ Allow unprivileged user-namespaces (needed by Chrome/Electron)…"
sudo tee /etc/sysctl.d/60-apparmor-userns.conf >/dev/null <<'EOF'
# Allow Chrome/Electron and other user-namespace tools to run without extra AppArmor rules
kernel.apparmor_restrict_unprivileged_userns = 0
EOF

# Apply immediately without reboot (harmless if the service name differs)
sudo systemctl restart systemd-sysctl.service 2>/dev/null || sudo sysctl -p /etc/sysctl.d/60-apparmor-userns.conf
echo "✓ AppArmor user-namespace restriction disabled persistently"