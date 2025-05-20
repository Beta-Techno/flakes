{ config, pkgs, lib, ... }:

{
  imports = [
    ../../gui/theme.nix
  ];

  # ── GNOME-specific settings ────────────────────────────────────
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
      dash-max-icon-size = 32;
      background-opacity = 0.8;
      show-apps-at-top = true;
      show-trash = true;
      show-mounts = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      titlebar-font = "JetBrainsMono Nerd Font Bold 11";
    };

    "org/gnome/desktop/notifications" = {
      show-banners = true;
      show-in-lock-screen = true;
    };

    "org/gnome/desktop/sound" = {
      theme-name = "freedesktop";
      event-sounds = true;
      input-feedback-sounds = true;
    };

    "org/gnome/desktop/thumbnailers" = {
      disable-all = false;
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [(lib.hm.gvariant.mkTuple ["xkb" "us"])];
      xkb-options = ["terminate:ctrl_alt_bksp"];
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = ["<Super>Tab"];
      switch-applications-backward = ["<Super><Shift>Tab"];
      switch-windows = ["<Alt>Tab"];
      switch-windows-backward = ["<Alt><Shift>Tab"];
      minimize = ["<Super>h"];
      maximize = ["<Super>Up"];
      unmaximize = ["<Super>Down"];
      close = ["<Super>q"];
    };
  };

  # ── GNOME packages ─────────────────────────────────────────────
  home.packages = with pkgs; [
    gnome-shell
    gnome-control-center
  ];
} 