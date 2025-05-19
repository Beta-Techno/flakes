{ config, pkgs, lib, ... }:

{
  # ── macOS specific settings ─────────────────────────────────────
  targets.darwin.defaults = {
    # Dock settings
    "com.apple.dock" = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
    };

    # Finder settings
    "com.apple.finder" = {
      FXPreferredViewStyle = "Nlsv";  # List view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Global settings
    "NSGlobalDomain" = {
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };
  };

  # ── Common macOS packages ───────────────────────────────────────
  home.packages = with pkgs; [
    # macOS utilities
    m-cli  # macOS command line tools
    mas    # Mac App Store command line interface
  ];

  # ── Homebrew configuration ─────────────────────────────────────
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "homebrew/cask"
      "homebrew/core"
    ];
    brews = [
      "mas"
    ];
    casks = [
      "google-chrome"
      "visual-studio-code"
      "postman"
      "jetbrains-toolbox"
    ];
  };
} 