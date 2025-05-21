{ config, pkgs, lib, helpers, ... }:

{
  # ── Chrome package ────────────────────────────────────────────
  home.packages = with pkgs; [
    helpers.chromeWrapped
    (lib.lowPrio google-chrome)  # icons / resources
  ];

  # ── Chrome launcher ────────────────────────────────────────────
  home.activation.installChromeLauncher = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    apps="${config.xdg.dataHome}/applications"
    mkdir -p "$apps"
    cat > "$apps/google-chrome.desktop" <<EOF
[Desktop Entry]
Name=Google Chrome
Exec=${helpers.chromeWrapped}/bin/google-chrome %U
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
  '';
} 