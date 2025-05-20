{ config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./lazyvim.nix
    ./doom.nix
  ];
} 