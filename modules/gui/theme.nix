{ config, pkgs, lib, ... }:

let
  # Theme package
  theme = pkgs.yaru-theme;
  # Wallpaper path
  wallpaperPath = ../../assets/wallpapers/fish.jpeg;
  # XDG data home with fallback
  xdgDataHome = config.home.homeDirectory + "/.local/share";
in
{
  # ── Theme configuration ─────────────────────────────────────────
  # Explicitly enable XDG support
  xdg.enable = true;

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
  home.activation = {
    copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${xdgDataHome}/backgrounds
      $DRY_RUN_CMD cp $VERBOSE_ARG ${wallpaperPath} ${xdgDataHome}/backgrounds/fish.jpeg
      echo "Copied wallpaper to ${xdgDataHome}/backgrounds/fish.jpeg"
    '';
  };

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
      picture-uri = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-uri-dark = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-options = "zoom";
      primary-color = "#000000";
      secondary-color = "#000000";
      color-shading-type = "solid";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-options = "zoom";
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