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
  # Enable XDG portal
  xdg = {
    portal = {
      enable = true;
      config = {
        # Common settings that apply to every desktop
        common = {
          default = [ "*" ];
        };

        # Interface-specific settings
        "org.freedesktop.impl.portal.FileChooser" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Screenshot" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Settings" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Wallpaper" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Notification" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Clipboard" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Device" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.AppChooser" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Background" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Inhibit" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Print" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Session" = {
          default = [ "gtk" ];
        };
        "org.freedesktop.impl.portal.Trash" = {
          default = [ "gtk" ];
        };
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