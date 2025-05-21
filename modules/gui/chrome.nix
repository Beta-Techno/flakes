{ config, pkgs, lib, helpers, ... }:

let
  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = helpers.chromeWrapped pkgs.google-chrome;

  # ── Chrome desktop entry ───────────────────────────────────────
  chromeDesktopEntry = helpers.createDesktopEntry {
    fileName = "google-chrome.desktop";   # Use canonical filename
    name = "Google Chrome";
    exec = "${chromeWrapped}/bin/google-chrome";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
  };
in
{
  # ── Chrome package ────────────────────────────────────────────
  home.packages = with pkgs; [
    chromeWrapped
    (lib.lowPrio google-chrome)  # icons / resources
  ];

  # ── Chrome launcher ────────────────────────────────────────────
  home.activation.installChromeLauncher = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    apps="${config.xdg.dataHome}/applications"
    mkdir -p "$apps"
    install -Dm644 ${chromeDesktopEntry}/google-chrome.desktop "$apps/google-chrome.desktop"
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
  '';
} 