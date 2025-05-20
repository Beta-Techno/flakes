{ lib, pkgs, config, ... }:

{
  # Only set the font through dconf
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "JetBrainsMono Nerd Font 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
    document-font-name = "JetBrainsMono Nerd Font 11";
    color-scheme = "prefer-dark";
  };

  # Set the background
  home.activation.copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD install -Dm644 -t ${config.xdg.dataHome}/backgrounds ${./../../assets/wallpapers/fish.jpeg}
  '';
}