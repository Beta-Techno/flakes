{ lib, pkgs, config, ... }:

let
  preferDark = true;
  accent = "purple";
  themeBase = "Yaru-${accent}";
  gtkTheme = themeBase + lib.optionalString preferDark "-dark";
in {
  # Set the font through dconf
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "JetBrainsMono Nerd Font 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
    document-font-name = "JetBrainsMono Nerd Font 11";
    color-scheme = "prefer-dark";
    gtk-theme = gtkTheme;
    icon-theme = themeBase;
  };

  # Set the background
  home.activation.copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/backgrounds
    $DRY_RUN_CMD cp ${./../../assets/wallpapers/fish.jpeg} ${config.xdg.dataHome}/backgrounds/fish.jpeg
  '';

  # Set the user avatar (both for session and login screen)
  home.file.".face" = {
    source = ./../../assets/icons/fish.png;
    onChange = ''
      chmod 644 $out
    '';
  };
}