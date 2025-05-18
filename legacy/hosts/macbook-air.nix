{ config, pkgs, ... }:

{
  # MacBook Air specific settings
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dash-max-icon-size = 24;  # Smaller icons for lower resolution
    };
  };
} 