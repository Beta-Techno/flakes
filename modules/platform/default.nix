{ platform, lib, ... }:

{
  imports = lib.flatten [
    (lib.optional platform.isLinux ./linux)
    (lib.optional platform.isDarwin ./darwin)
  ];
} 