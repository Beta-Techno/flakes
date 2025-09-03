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