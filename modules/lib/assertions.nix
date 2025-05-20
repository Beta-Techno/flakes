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
  ## Expose the pre-computed platform record as read-only
  options.platform = mkOption {
    type        = types.attrs;
    default     = platform;
    readOnly    = true;
    description = "Platform detection and capabilities passed via specialArgs";
  };

  ## Example: Darwin-only config (safe – evaluated after the graph exists)
  config = mkIf platform.isDarwin {
    assertions = [{
      assertion = platform.isDarwin;
      message   = "Darwin-specific profile imported on a non-Darwin host";
    }];
  };
} 