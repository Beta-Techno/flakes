{ config, pkgs, lib, ... }:

{
  imports = [ ../modules/common.nix ];

  ############################  Machine Specific  #############################
  # MacBook Air (2014) - Intel HD 5000 specific settings
  home.packages = with pkgs; [
    # Add any Air-specific packages here
  ];

  # Air-specific performance tweaks
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      # Air-specific dock settings
      dash-max-icon-size = 24;  # Smaller icons for Air's lower resolution
    };
  };
} 