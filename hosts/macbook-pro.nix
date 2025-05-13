{ config, pkgs, ... }:

{
  # MacBook Pro specific settings
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dash-max-icon-size = 32;  # Larger icons for higher resolution
    };
  };
} 