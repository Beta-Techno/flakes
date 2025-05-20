{ config, pkgs, lib, ... }:

{
  imports = lib.optional config.isLinux ./linux
    ++ lib.optional config.isDarwin ./darwin;
} 