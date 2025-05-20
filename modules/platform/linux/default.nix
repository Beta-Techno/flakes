{ platform, pkgs, lib, ... }:

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
      clang
      cmake
      pkg-config
      openssl
      zlib
      libffi
      python3
      nodejs
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
    ] 
    ++ lib.optionals platform.hasAMD [
      # AMD GPU specific packages
      rocm-opencl-runtime
      rocm-opencl-icd
      rocm-smi
      rocm-device-libs
      rocm-runtime
      rocm-thunk
      rocm-llvm
      rocm-cmake
    ];

  # ── Desktop environment detection ───────────────────────────────
  imports = lib.flatten [
    (lib.optional platform.hasGnome ./desktop/gnome.nix)
    (lib.optional platform.hasKDE ./desktop/kde.nix)
    (lib.optional platform.isWSL ./wsl.nix)
  ];

  # ── Systemd user services ───────────────────────────────────────
  systemd.user.services = lib.mkIf platform.hasSystemd {
    # Add systemd user services here
  };

  # ── X11 configuration ───────────────────────────────────────────
  xsession = {
    enable = true;
    windowManager.command = "i3";
  };
} 