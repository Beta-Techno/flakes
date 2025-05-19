{ config, pkgs, lib, ... }:

{
  # ── MacBook Pro specific settings ───────────────────────────────
  # macOS settings
  targets.darwin.defaults = {
    # Dock settings for higher resolution display
    "com.apple.dock" = {
      tilesize = 64;  # Larger icons for higher resolution
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
      dash-max-icon-size = 32;  # Larger icons for higher resolution
    };
  };
} 