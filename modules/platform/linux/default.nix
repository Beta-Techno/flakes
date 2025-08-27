{ pkgs, lib, ... }:

{
  # ── Platform-specific settings ──────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── Common Linux packages ───────────────────────────────────────
  home.packages = with pkgs; 
    [ 
      # Core utilities
      coreutils
      gnused
      gnugrep
      findutils
      which
      file
      tree
      htop
      ripgrep
      fd
      bat
      eza
      fzf
      jq
      yq-go
      tmux
      git
      git-lfs
      gnumake
      gcc
      cmake
      pkg-config
      openssl
      zlib
      libffi
      python3
      rustc
      cargo
      go
      gopls
      gotools
      shellcheck
      shfmt
      nixpkgs-fmt
      nixfmt
      nil
      nixd
      nixos-option
      nixos-rebuild
      nixos-generators
      nixos-enter

      # X11 utilities
      xorg.xrandr
      xorg.xset
      xorg.xsetroot
      xorg.xrdb

      # System utilities
      pciutils
      usbutils
      lshw
    ];

  # ── Desktop environment detection ───────────────────────────────
  imports = lib.flatten [
    (lib.optional (builtins.pathExists "/usr/bin/gnome-shell") ./desktop/gnome.nix)
    (lib.optional (builtins.pathExists "/usr/bin/plasmashell") ./desktop/kde.nix)
    (lib.optional (builtins.pathExists "/proc/version" && builtins.readFile "/proc/version" != "" && builtins.match ".*Microsoft.*" (builtins.readFile "/proc/version") != null) ./wsl.nix)
  ];

  # ── Systemd user services ───────────────────────────────────────
  systemd.user.services = lib.mkIf (builtins.pathExists "/run/systemd/system") {
    # Add systemd user services here
  };

  # ── X11 configuration ───────────────────────────────────────────
  xsession = {
    enable = true;
    windowManager.command = "i3";
  };
} 