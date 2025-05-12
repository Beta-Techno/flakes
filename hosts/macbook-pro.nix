{ config, pkgs, lib, ... }:

{
  imports = [ ../modules/common.nix ];

  ############################  Machine Specific  #############################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";

  # MacBook Pro 13" (2015) - Intel Iris 6100 specific settings
  home.packages = with pkgs; [
    # Add any Pro-specific packages here
  ];

  # Pro-specific performance tweaks
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      # Pro-specific dock settings
      dash-max-icon-size = 32;  # Larger icons for Pro's higher resolution
    };
  };
} 