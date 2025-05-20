{ config, pkgs, lib, ... }:

{
  imports = lib.optional config.platform.isLinux ./linux
    ++ lib.optional config.platform.isDarwin ./darwin;
} 