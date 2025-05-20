{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, doomConfig, nixGL, ... }:

let
  helpers = import ../modules/lib/helpers.nix { inherit pkgs lib; };
in
{
  imports = [
    # Core modules
    ../modules/core/base.nix
    ../modules/lib/assertions.nix

    # Platform-specific modules
    ../modules/platform/linux

    # Tool modules
    ../modules/tools
    ../modules/editors
    ../modules/terminal

    # GUI modules
    ../modules/gui
  ];

  # ── Linux-specific settings ───────────────────────────────────
  # Enable GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
  };

  # Enable Qt theming
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Enable XDG portal
  xdg = {
    portal = {
      enable = true;
      config = {
        common.default = "*";
        # Explicitly set portal backends for each interface
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
        "org.freedesktop.impl.portal.Screenshot" = "gtk";
        "org.freedesktop.impl.portal.Settings" = "gtk";
        "org.freedesktop.impl.portal.Wallpaper" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.Clipboard" = "gtk";
        "org.freedesktop.impl.portal.Device" = "gtk";
        "org.freedesktop.impl.portal.AppChooser" = "gtk";
        "org.freedesktop.impl.portal.Background" = "gtk";
        "org.freedesktop.impl.portal.Inhibit" = "gtk";
        "org.freedesktop.impl.portal.Print" = "gtk";
        "org.freedesktop.impl.portal.Session" = "gtk";
        "org.freedesktop.impl.portal.Trash" = "gtk";
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };
  };

  # ── Editor configurations ──────────────────────────────────────
  # Pass special arguments to editor modules
  _module.args = {
    inherit lazyvimStarter lazyvimConfig doomConfig nixGL helpers;
  };
} 