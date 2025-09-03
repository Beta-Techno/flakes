{ lib, pkgs, config, ... }:

let
  preferDark = true;
  accent = "purple";
  themeBase = "Yaru-${accent}";
  gtkTheme = themeBase + lib.optionalString preferDark "-dark";
in {
  # Set the font through dconf (user-level)
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "JetBrainsMono Nerd Font 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
    document-font-name = "JetBrainsMono Nerd Font 11";
    color-scheme = "prefer-dark";
    gtk-theme = gtkTheme;
    icon-theme = themeBase;
  };

  # Set the background (user-level, using absolute path)
  dconf.settings."org/gnome/desktop/background" = {
    picture-uri = "file:///home/nbg/.local/share/backgrounds/fish.jpeg";
    picture-uri-dark = "file:///home/nbg/.local/share/backgrounds/fish.jpeg";
    picture-options = "zoom";
  };

  # ── GNOME-specific user settings ────────────────────────────────────
  dconf.settings."org/gnome/shell" = {
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

  dconf.settings."org/gnome/shell/extensions/dash-to-dock" = {
    dock-position = "LEFT";
    autohide = false;
    dash-max-icon-size = 32;
    background-opacity = 0.8;
    show-apps-at-top = true;
    show-trash = true;
    show-mounts = true;
  };

  dconf.settings."org/gnome/desktop/wm/preferences" = {
    button-layout = "appmenu:minimize,maximize,close";
    titlebar-font = "JetBrainsMono Nerd Font Bold 11";
  };

  dconf.settings."org/gnome/desktop/notifications" = {
    show-banners = true;
    show-in-lock-screen = true;
  };

  dconf.settings."org/gnome/desktop/sound" = {
    theme-name = "freedesktop";
    event-sounds = true;
    input-feedback-sounds = true;
  };

  dconf.settings."org/gnome/desktop/thumbnailers" = {
    disable-all = false;
  };

  dconf.settings."org/gnome/desktop/calendar" = {
    show-weekdate = true;
  };

  dconf.settings."org/gnome/desktop/peripherals/touchpad" = {
    tap-to-click = true;
    two-finger-scrolling-enabled = true;
  };

  dconf.settings."org/gnome/desktop/peripherals/mouse" = {
    natural-scroll = false;
  };

  dconf.settings."org/gnome/desktop/input-sources" = {
    sources = [(lib.hm.gvariant.mkTuple ["xkb" "us"])];
    xkb-options = ["terminate:ctrl_alt_bksp"];
  };

  dconf.settings."org/gnome/desktop/wm/keybindings" = {
    switch-applications = ["<Super>Tab"];
    switch-applications-backward = ["<Super><Shift>Tab"];
    switch-windows = ["<Alt>Tab"];
    switch-windows-backward = ["<Alt><Shift>Tab"];
    minimize = ["<Super>h"];
    maximize = ["<Super>Up"];
    unmaximize = ["<Super>Down"];
    close = ["<Super>q"];
  };

  # Note: Dock configuration is already defined above in the GNOME-specific user settings section

  # Set the user avatar (both for session and login screen)
  home.file.".face" = {
    source = ./../../assets/icons/fish.png;
  };

  # Copy wallpaper to user directory
  home.activation.copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ~/.local/share/backgrounds
    $DRY_RUN_CMD cp -f ${./../../assets/wallpapers/fish.jpeg} ~/.local/share/backgrounds/fish.jpeg
  '';
}