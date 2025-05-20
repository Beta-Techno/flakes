{ config, pkgs, lib, hasAMD, ... }:

let
  inherit (import ../../lib/assertions.nix { inherit pkgs lib; })
    hasSystemd
    hasNvidia
    hasGnome
    hasKDE
    isWSL;
in
{
  # ── Platform-specific settings ──────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── System packages ────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
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
    exa
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
    nixos-generate-config
    nixos-enter
  ] // lib.optionalAttrs hasAMD [
    # AMD GPU specific packages
    rocm-opencl-runtime
    rocm-opencl-icd
    rocm-smi
    rocm-device-libs
    rocm-runtime
    rocm-thunk
    rocm-llvm
    rocm-cmake
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
  imports = lib.optional hasGnome ./desktop/gnome.nix
    ++ lib.optional hasKDE ./desktop/kde.nix
    ++ lib.optional isWSL ./wsl.nix;

  # ── Systemd user services ───────────────────────────────────────
  systemd.user.services = lib.mkIf hasSystemd {
    # Add systemd user services here
  };

  # ── X11 configuration ───────────────────────────────────────────
  xsession = {
    enable = true;
    windowManager.command = "i3";
  };

  # ── Graphics configuration ──────────────────────────────────────
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  } // lib.optionalAttrs hasNvidia {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
    };
  } // lib.optionalAttrs hasAMD {
    amdgpu = {
      enable = true;
    };
  };

  # ── Common Linux packages ───────────────────────────────────────
  home.packages = with pkgs; [
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
} 