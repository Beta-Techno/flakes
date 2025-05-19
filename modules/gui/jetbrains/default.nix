{ config, pkgs, lib, ... }:

{
  imports = [
    ./rider.nix
    ./datagrip.nix
  ];
} 