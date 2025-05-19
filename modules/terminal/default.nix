{ config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./alacritty.nix
  ];

  _module.args = {
    inherit helpers;
  };
} 