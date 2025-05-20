{ config, pkgs, lib, username, doomConfig, ... }:

{
  home.packages = with pkgs; [
    # Dependencies
    ripgrep
    fd
    imagemagick
    sqlite
    zstd
  ];

  # Enable Doom Emacs
  programs = {
    doom-emacs = {
      enable = true;
      doomDir = doomConfig;
      emacs = pkgs.emacs30-pgtk;
      doomLocalDir = "/home/${username}/.local/share/doom";
    };
  };

  # Use the templates from home/editors/doom
  home.file = {
    ".doom.d/init.el".source = "${doomConfig}/init.el";
    ".doom.d/packages.el".source = "${doomConfig}/packages.el";
    ".doom.d/config.el".source = "${doomConfig}/config.el";
  };
} 