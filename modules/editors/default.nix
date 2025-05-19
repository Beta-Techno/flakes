{ config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./lazyvim.nix
    ./doom.nix
  ];

  _module.args = {
    inherit helpers;
  };
} 