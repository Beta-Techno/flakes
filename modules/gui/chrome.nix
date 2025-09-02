{ config, pkgs, lib, ... }:
let
  isLinux  = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # keep it simple & portable for HM:
  # - NixOS/Linux → google-chrome (unfree)
  # - macOS      → chromium (pure Nix; Chrome via Homebrew should live in nix-darwin, not HM)
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  home.packages = [
    (if isDarwin then pkgs.chromium else pkgs.google-chrome)
  ];
} 