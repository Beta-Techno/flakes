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
    desktop-file-utils  # Add this for update-desktop-database
  ];

  # ── Chrome launcher ────────────────────────────────────────────
  home.file."${config.xdg.dataHome}/applications/google-chrome.desktop" = {
    source = "${chromeDesktopEntry}/google-chrome.desktop";
  };

  # ── Update desktop database ────────────────────────────────────
  home.activation.updateDesktopDatabase = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database ${config.xdg.dataHome}/applications || true
  '';
} 