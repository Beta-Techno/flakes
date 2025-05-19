{ pkgs, lib }:

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

in {
  inherit
    isDarwin
    isLinux
    isWSL
    hasSystemd
    hasNvidia
    hasAMD
    hasGnome
    hasKDE;
} 