{ config, pkgs, lib, ... }:

{
  # ── GNOME-specific system settings ────────────────────────────────────
  # Note: This module contains only system-level GNOME configuration
  # User-level dconf settings are handled in the Home-Manager theme module
  
  # GNOME is already enabled via services.xserver.desktopManager.gnome.enable
  # and services.xserver.displayManager.gdm.enable in the VM configuration
  
  # Add any additional system-level GNOME configuration here if needed
} 