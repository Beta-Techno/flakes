{ lib, pkgs, ... }:

{
  imports = lib.flatten [
    (lib.optional pkgs.stdenv.isLinux ./linux)
  ];
} 