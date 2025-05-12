{ config, pkgs, lib, ... }:

{
  # MacBook Pro 13" (2015) - Intel Iris 6100 specific settings
  dconf.settings."org/gnome/shell/extensions/dash-to-dock" = {
    dash-max-icon-size = lib.mkForce 32;  # Larger icons for Pro's higher resolution
  };
} 