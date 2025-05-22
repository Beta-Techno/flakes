#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "+ downloading installer..."
curl -fsSL https://raw.githubusercontent.com/Beta-Techno/flakes/main/scripts/install.sh \
  -o "$tmp/install.sh"

chmod +x "$tmp/install.sh"

# run as current user; inner script keeps its own sudo calls
echo "+ running installer..."
exec "$tmp/install.sh" 




# TO RUN:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/Beta-Techno/flakes/main/scripts/init.sh)"