{ config, pkgs, lib, ... }:

{
  # ── MacBook Air specific settings ───────────────────────────────
  # macOS settings
  targets.darwin.defaults = {
    # Dock settings for lower resolution display
    "com.apple.dock" = {
      tilesize = 48;  # Smaller icons for lower resolution
      autohide = true;
      show-recents = false;
    };

    # Finder settings
    "com.apple.finder" = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";  # List view
    };
  };

  # Linux settings (if applicable)
  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dash-max-icon-size = 24;  # Smaller icons for lower resolution
    };
  };
} 