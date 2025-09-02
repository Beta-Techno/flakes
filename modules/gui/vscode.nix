{ config, pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = lib.mkDefault true;
  home.packages = [ pkgs.vscode ];  # or pkgs.vscodium without unfree
} 