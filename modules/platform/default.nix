{ platform, lib, ... }:

{
  imports = lib.optional platform.isLinux ./linux
  imports = lib.optional config.platform.isLinux ./linux
    ++ lib.optional config.platform.isDarwin ./darwin;
} 