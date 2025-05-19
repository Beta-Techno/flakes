{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
  ];

  programs.git = {
    enable = true;
    userName = "Rob";
    userEmail = "rob@example.com";
    lfs.enable = true;
  };
} 