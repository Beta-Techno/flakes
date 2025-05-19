{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    jetbrains.rider
  ];
} 