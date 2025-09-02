{ config, pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = lib.mkDefault true;
  home.packages = [ pkgs.postman ];
} 