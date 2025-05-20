{ config, pkgs, lib, ... }:

let
  # Theme package - use Ubuntu's official package
  yaruUbuntu = pkgs.deb2nix.buildDebPackage {
    url = "https://mirrors.kernel.org/ubuntu/pool/main/y/yaru-theme/yaru-theme_24.04.1_all.deb";
    sha256 = "0lqlp93sf2n8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q";  # TODO: Get actual hash
  };
  # Wallpaper path
  wallpaperPath = ../../assets/wallpapers/fish.jpeg;
  # XDG data home with fallback
  xdgDataHome = config.home.homeDirectory + "/.local/share";
in
{
  # ── Theme configuration ─────────────────────────────────────────
  # Explicitly enable XDG support
  xdg.enable = true;

  # Put Ubuntu's data dir after the Nix profile
  home.sessionVariables = {
    XDG_DATA_DIRS = lib.mkForce "${config.home.profileDirectory}/share:/usr/share";
  };

  # GTK Theme
  gtk = {
    enable = true;
    theme = {
      name = "Yaru-dark";  # Plain Yaru-dark without color suffix
      package = yaruUbuntu;
    };
    iconTheme = {
      name = "Yaru";  # Plain Yaru without color suffix
      package = yaruUbuntu;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  # Qt Theme
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "yaru-dark";
      package = null;  # Let the system use the GTK theme
    };
  };

  # Cursor Theme
  home.pointerCursor = {
    name = "Yaru-dark";
    package = yaruUbuntu;
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
      accent-color = "purple";  # This should now work with Ubuntu's schemas
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Yaru-dark";
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-uri-dark = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-options = "zoom";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${xdgDataHome}/backgrounds/fish.jpeg";
      picture-options = "zoom";
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "trayIconsReloaded@selfmade.pl"
      ];
      color-scheme = "prefer-dark";
    };
  };

  # ── GNOME Extensions ────────────────────────────────────────────
  home.packages = with pkgs; [
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.appindicator
    gnomeExtensions.tray-icons-reloaded
  ];
} 