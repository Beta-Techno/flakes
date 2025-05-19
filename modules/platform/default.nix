{ config, pkgs, lib, ... }:

let
  inherit (import ../lib/assertions.nix { inherit pkgs lib; })
    isLinux
    isDarwin;
in
{
  imports = lib.optional isLinux ./linux
    ++ lib.optional isDarwin ./darwin;
} 