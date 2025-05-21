{ config, pkgs, lib, helpers, ... }:

let
  # ── Chrome desktop entry ───────────────────────────────────────
  chromeDesktopEntry = helpers.createDesktopEntry {
    fileName = "google-chrome.desktop";   # Use canonical filename
    name = "Google Chrome";
    exec = "${helpers.chromeWrapped}/bin/google-chrome";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };
in
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
    install -Dm644 ${chromeDesktopEntry} "$apps/google-chrome.desktop"
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true

    # Install Chrome sandbox executable
    if [ ! -e /usr/local/bin/chrome-sandbox ]; then
      echo "Installing Chrome sandbox executable..."
      sudo install -m 4755 ${pkgs.google-chrome}/libexec/chrome-sandbox /usr/local/bin/chrome-sandbox
    fi
  '';
} 