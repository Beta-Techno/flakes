{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
  ];

  programs.git = {
    enable = true;
    # Let auth tool set these initially, then they persist via NixOS
    userName = lib.mkDefault "Rob";
    userEmail = lib.mkDefault "rob@example.com";
    lfs.enable = true;
  };
} 