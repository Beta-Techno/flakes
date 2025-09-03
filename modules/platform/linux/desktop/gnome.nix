{ config, pkgs, lib, ... }:

{
  # ── GNOME-specific system settings ────────────────────────────────────
  # Note: This module contains only system-level GNOME configuration
  # User-level dconf settings are handled in the Home-Manager theme module
  
  # GNOME shell extensions
  programs.gnome-extensions = {
    enable = true;
    # Add any system-level extension management here if needed
  };
} 