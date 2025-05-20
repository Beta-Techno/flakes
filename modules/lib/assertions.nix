{ lib, platform, ... }:

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
  options.platform = lib.mkOption {
    type = lib.types.attrs;
    default = platform;
    readOnly = true;
    description = "Platform detection and capabilities";
  };

  # ── Darwin-specific config ─────────────────────────────────────
  config = mkIf isDarwin {
    # Add Darwin-specific config here if needed
  };
} 