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
  options = {
    # ── Platform detection ──────────────────────────────────────────
    isDarwin = lib.mkOption {
      type = lib.types.bool;
      default = isDarwin;
      readOnly = true;
      description = "Whether the system is running macOS";
    };
    isLinux = lib.mkOption {
      type = lib.types.bool;
      default = isLinux;
      readOnly = true;
      description = "Whether the system is running Linux";
    };
    isWSL = lib.mkOption {
      type = lib.types.bool;
      default = isWSL;
      readOnly = true;
      description = "Whether the system is running in WSL";
    };

    # ── System capabilities ─────────────────────────────────────────
    hasSystemd = lib.mkOption {
      type = lib.types.bool;
      default = hasSystemd;
      readOnly = true;
      description = "Whether the system uses systemd";
    };
    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = hasNvidia;
      readOnly = true;
      description = "Whether the system has an NVIDIA GPU";
    };
    hasAMD = lib.mkOption {
      type = lib.types.bool;
      default = hasAMD;
      readOnly = true;
      description = "Whether the system has an AMD GPU";
    };

    # ── Desktop environment detection ───────────────────────────────
    hasGnome = lib.mkOption {
      type = lib.types.bool;
      default = hasGnome;
      readOnly = true;
      description = "Whether GNOME is installed";
    };
    hasKDE = lib.mkOption {
      type = lib.types.bool;
      default = hasKDE;
      readOnly = true;
      description = "Whether KDE is installed";
    };
  };
}

# ── Darwin-specific options ─────────────────────────────────────
options = lib.mkIf isDarwin {
  # Add Darwin-specific options here if needed
}; 