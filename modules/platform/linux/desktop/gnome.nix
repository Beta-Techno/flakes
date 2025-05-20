{ config, pkgs, lib, ... }:

let
  # Create a derivation that copies the wallpaper to the Nix store
  wallpaper = pkgs.runCommand "wallpaper" {} ''
    mkdir -p $out/share/backgrounds
    cp ${./../../../assets/wallpapers/fish.jpeg} $out/share/backgrounds/wallpaper.jpeg
  '';
in
{
  # ── GNOME-specific settings ────────────────────────────────────
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
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash-to-dock@micxgx.gmail.com"
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
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      titlebar-font = "JetBrainsMono Nerd Font Bold 11";
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file://${wallpaper}/share/backgrounds/wallpaper.jpeg";
      picture-uri-dark = "file://${wallpaper}/share/backgrounds/wallpaper.jpeg";
      primary-color = "#3071AE";
      secondary-color = "#000000";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${wallpaper}/share/backgrounds/wallpaper.jpeg";
      primary-color = "#3071AE";
      secondary-color = "#000000";
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
    gnome-tweaks
    gnome-shell-extensions
    gnome-backgrounds
    gnome-themes-extra
    yaru-theme
    gnome-shell
    gnome-control-center
  ];
} 