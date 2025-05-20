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
    platformTheme = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Enable XDG portal
  xdg = {
    portal = {
      enable = true;
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