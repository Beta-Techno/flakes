{ lib, ... }:

let
  inherit (lib) mkOption types mkIf;

  # ── Platform detection (pure builtins) ──────────────────────────
  isDarwin = builtins.match ".*-darwin" builtins.currentSystem != null;
  isLinux = builtins.match ".*-linux" builtins.currentSystem != null;
  isWSL = isLinux && builtins.pathExists "/proc/version" && 
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
  options.platform = {
    # ── Platform detection ──────────────────────────────────────────
    isDarwin = mkOption {
      type = types.bool;
      default = isDarwin;
      readOnly = true;
      description = "Whether the system is running macOS";
    };
    isLinux = mkOption {
      type = types.bool;
      default = isLinux;
      readOnly = true;
      description = "Whether the system is running Linux";
    };
    isWSL = mkOption {
      type = types.bool;
      default = isWSL;
      readOnly = true;
      description = "Whether the system is running in WSL";
    };

    # ── System capabilities ─────────────────────────────────────────
    hasSystemd = mkOption {
      type = types.bool;
      default = hasSystemd;
      readOnly = true;
      description = "Whether the system uses systemd";
    };
    hasNvidia = mkOption {
      type = types.bool;
      default = hasNvidia;
      readOnly = true;
      description = "Whether the system has an NVIDIA GPU";
    };
    hasAMD = mkOption {
      type = types.bool;
      default = hasAMD;
      readOnly = true;
      description = "Whether the system has an AMD GPU";
    };

    # ── Desktop environment detection ───────────────────────────────
    hasGnome = mkOption {
      type = types.bool;
      default = hasGnome;
      readOnly = true;
      description = "Whether GNOME is installed";
    };
    hasKDE = mkOption {
      type = types.bool;
      default = hasKDE;
      readOnly = true;
      description = "Whether KDE is installed";
    };
  };

  # ── Darwin-specific config ─────────────────────────────────────
  config = mkIf isDarwin {
    # Add Darwin-specific config here if needed
  };
} 