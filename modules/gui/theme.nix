{ lib, pkgs, config, ... }:

let
  # 1.  Ubuntu-built Yaru with colour-aware CSS
  yaruUbuntu = pkgs.stdenvNoCC.mkDerivation rec {
    pname   = "yaru-theme-ubuntu";
    version = "24.04.1";
    src = pkgs.fetchurl {
      url    = "https://mirrors.kernel.org/ubuntu/pool/main/y/yaru-theme/${pname}_${version}_all.deb";
      hash   = "sha256:…";                  # paste nix hash here
    };
    unpackCmd   = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out
      mv usr/share $out/
    '';
  };
in
{
  ## — GTK, icon & cursor themes (unchanged) —
  gtk = {
    enable = true;
    theme.name      = "Yaru-dark";
    theme.package   = yaruUbuntu;
    iconTheme.name  = "Yaru";
    iconTheme.package = yaruUbuntu;
    font = { name = "JetBrainsMono Nerd Font"; size = 11; };
  };

  home.pointerCursor = {
    name    = "Yaru-dark";
    package = yaruUbuntu;
    size    = 24;
  };

  ## — Fonts, hot-corners, battery %, etc. —
  dconf.enable = true;
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme            = "Yaru-dark";
    icon-theme           = "Yaru";
    cursor-theme         = "Yaru";
    color-scheme         = "prefer-dark";
    accent-color         = "purple";        # ♥  works now
    font-name            = "JetBrainsMono Nerd Font 11";
    monospace-font-name  = "JetBrainsMono Nerd Font 11";
    document-font-name   = "JetBrainsMono Nerd Font 11";
    enable-hot-corners   = true;
    show-battery-percentage = true;
  };

  ## — GNOME Shell theme via User-Theme extension —
  dconf.settings."org/gnome/shell/extensions/user-theme".name = "Yaru-dark";

  ## — Shell options & extensions (unchanged) —
  dconf.settings."org/gnome/shell" = {
    color-scheme = "prefer-dark";
    enabled-extensions = [
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "appindicatorsupport@rgcjonas.gmail.com"
      "trayIconsReloaded@selfmade.pl"
    ];
  };

  ## — Wallpaper copy helper (unchanged) —
  home.activation.copyWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD install -Dm644 -t ${config.xdg.dataHome}/backgrounds ${./../../assets/wallpapers/fish.jpeg}
  '';

  ## — Extras you like —
  home.packages = with pkgs; [
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.appindicator
    gnomeExtensions.tray-icons-reloaded
  ];
}