{ config, pkgs, lib, ... }:

{
  # ── KDE-specific settings ──────────────────────────────────────
  home.packages = with pkgs; [
    # KDE utilities
    kdeconnect
    kate
    dolphin
  ];
} 