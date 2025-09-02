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

  # Enable Emacs (Doom will be configured via home.file)
  programs.emacs = {
    enable = true;
    package = pkgs.emacs30-pgtk;
  };

  # Use the templates from home/editors/doom
  home.file = {
    ".doom.d/init.el".source = "${doomConfig}/init.el";
    ".doom.d/packages.el".source = "${doomConfig}/packages.el";
    ".doom.d/config.el".source = "${doomConfig}/config.el";
  };
} 