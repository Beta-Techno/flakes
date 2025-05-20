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
    $DRY_RUN_CMD install -Dm644 -t ${config.xdg.dataHome}/backgrounds ${./../../assets/wallpapers/fish.jpeg}
  '';

  # Set the user avatar (both for session and login screen)
  home.file.".face" = {
    source = ./../../assets/icons/fish.png;
    onChange = ''
      chmod 644 $out
    '';
  };

  # Use AccountsService to set the avatar for GDM
  home.activation.avatar = lib.hm.dag.entryAfter ["linkGeneration"] ''
    pic=${./../../assets/icons/fish.png}
    uid=$(id -u)

    # Ask AccountsService to copy & register the icon
    busctl --system call org.freedesktop.Accounts \
           /org/freedesktop/Accounts/User${uid} \
           org.freedesktop.Accounts.User SetIconFile s "$pic" \
      || echo "warning: could not set avatar"
  '';
}