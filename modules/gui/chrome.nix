{ config, pkgs, lib, helpers, ... }:

let
  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = helpers.chromeWrapped pkgs.google-chrome;

  # ── Chrome desktop entry ───────────────────────────────────────
  chromeDesktopEntry = helpers.createDesktopEntry {
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
  home.file."${config.xdg.dataHome}/applications/google-chrome.desktop" = {
    source = "${chromeDesktopEntry}/Google Chrome.desktop";
  };
} 