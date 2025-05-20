{ config, pkgs, lib, ... }:

let
  # Theme package
  theme = pkgs.yaru-theme;
in
{
  # ── Theme configuration ─────────────────────────────────────────
  # GTK Theme
  gtk = {
    enable = true;
    theme = {
      name = lib.mkDefault "Yaru-dark";
      package = lib.mkDefault theme;
    };
    iconTheme = {
      name = lib.mkDefault "Yaru";
      package = lib.mkDefault theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  # Qt Theme
  qt = {
    enable = true;
    platformTheme = lib.mkDefault "gtk";
    style = {
      name = lib.mkDefault "yaru-dark";
      package = lib.mkDefault theme;
    };
  };

  # Cursor Theme
  home.pointerCursor = {
    name = "Yaru-dark";
    package = theme;
    size = 24;
  };

  # ── Wallpaper Configuration ─────────────────────────────────────
  xdg.dataFile."wallpapers/background.jpg".source = ./../../assets/wallpapers/fish.jpeg;

  # ── GNOME Theme Settings ────────────────────────────────────────
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Yaru-dark";
      icon-theme = "Yaru";
      cursor-theme = "Yaru";
      font-name = "JetBrainsMono Nerd Font 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
      document-font-name = "JetBrainsMono Nerd Font 11";
      enable-hot-corners = true;
      show-battery-percentage = true;
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Yaru-dark";
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.xdg.dataHome}/wallpapers/background.jpg";
      picture-uri-dark = "file://${config.xdg.dataHome}/wallpapers/background.jpg";
      primary-color = "#000000";
      secondary-color = "#000000";
      color-shading-type = "solid";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${config.xdg.dataHome}/wallpapers/background.jpg";
      primary-color = "#000000";
      secondary-color = "#000000";
      color-shading-type = "solid";
    };
  };

  # ── GNOME Extensions ────────────────────────────────────────────
  home.packages = with pkgs; [
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.appindicator
    gnomeExtensions.tray-icons-reloaded
  ];

  # Enable required extensions
  dconf.settings."org/gnome/shell".enabled-extensions = [
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "trayIconsReloaded@selfmade.pl"
  ];
} 