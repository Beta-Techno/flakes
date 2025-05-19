{ config, pkgs, lib, ... }:

let
  inherit (import ../../lib/assertions.nix { inherit pkgs lib; })
    hasSystemd
    hasNvidia
    hasAMD
    hasGnome
    hasKDE
    isWSL;
in
{
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