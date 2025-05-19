{ config, pkgs, lib, ... }:

{
  # ── Dock / sidebar configuration ────────────────────────────────
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "alacritty.desktop"
        "org.gnome.Terminal.desktop"
        "emacs.desktop"
        "google-chrome.desktop"
        "code.desktop"
        "rider.desktop"
        "datagrip.desktop"
        "postman.desktop"
      ];
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      autohide = false;
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
} 