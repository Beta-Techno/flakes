{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, doomConfig, nixGL, ... }:

let
  helpers = import ../modules/lib/helpers.nix { inherit pkgs lib; };
in
{
  imports = [
    # Core modules
    ../modules/core/base.nix
    ../modules/lib/assertions.nix

    # Platform-specific modules
    ../modules/platform/darwin

    # Tool modules
    ../modules/tools
    ../modules/editors
    ../modules/terminal

    # GUI modules
    ../modules/gui
  ];

  # ── Darwin-specific settings ───────────────────────────────────
  targets.darwin.defaults = {
    # Enable key repeat
    "ApplePressAndHoldEnabled" = false;

    # Dock settings
    "com.apple.dock" = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
    };

    # Finder settings
    "com.apple.finder" = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";  # List view
    };

    # Global settings
    "GlobalDomain" = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };
  };

  # Pass special arguments to editor modules
  _module.args = {
    inherit lazyvimStarter lazyvimConfig doomConfig nixGL helpers;
  };
} 