{ config, pkgs, lib, username, doomConfig, ... }:

{
  # Dependencies for Doom Emacs
  home.packages = with pkgs; [
    ripgrep
    fd
    imagemagick
    sqlite
    zstd
  ];
} 