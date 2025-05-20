{ config, pkgs, lib, ... }:

let
  # ── Platform detection ──────────────────────────────────────────
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isWSL = pkgs.stdenv.isLinux && builtins.pathExists "/proc/version" && 
          builtins.readFile "/proc/version" != "" && 
          builtins.match ".*Microsoft.*" (builtins.readFile "/proc/version") != null;

  # ── System capabilities ─────────────────────────────────────────
  hasSystemd = isLinux && !isWSL;
  hasNvidia = isLinux && builtins.pathExists "/proc/driver/nvidia";
  hasAMD = isLinux && builtins.pathExists "/sys/class/drm/card0/device/vendor" && 
           builtins.readFile "/sys/class/drm/card0/device/vendor" == "0x1002\n";

  # ── Desktop environment detection ───────────────────────────────
  hasGnome = isLinux && builtins.pathExists "/usr/bin/gnome-shell";
  hasKDE = isLinux && builtins.pathExists "/usr/bin/plasmashell";
in
{
  # ── Platform detection ──────────────────────────────────────────
  assertions = {
    inherit isDarwin isLinux isWSL;
  };

  # ── Platform-specific options ───────────────────────────────────
  options = {
    # Linux-specific options
    hasSystemd = lib.mkOption {
      type = lib.types.bool;
      default = hasSystemd;
      readOnly = true;
      visible = isLinux;
    };
    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = hasNvidia;
      readOnly = true;
      visible = isLinux;
    };
    hasAMD = lib.mkOption {
      type = lib.types.bool;
      default = hasAMD;
      readOnly = true;
      visible = isLinux;
    };
    hasGnome = lib.mkOption {
      type = lib.types.bool;
      default = hasGnome;
      readOnly = true;
      visible = isLinux;
    };
    hasKDE = lib.mkOption {
      type = lib.types.bool;
      default = hasKDE;
      readOnly = true;
      visible = isLinux;
    };
  };

  # ── Darwin-specific options ─────────────────────────────────────
  options = lib.mkIf isDarwin {
    # Add Darwin-specific options here if needed
  };
} 