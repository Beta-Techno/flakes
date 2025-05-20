{ config, pkgs, lib, ... }:

{
  # ── AMD GPU specific packages ───────────────────────────────────
  environment.systemPackages = lib.optionalAttrs config.platform.hasAMD (with pkgs; [
    rocm-opencl-runtime
    rocm-opencl-icd
    rocm-smi
    rocm-device-libs
    rocm-runtime
    rocm-thunk
    rocm-llvm
    rocm-cmake
  ]);

  # ── Desktop environment detection ───────────────────────────────
  imports = lib.optional config.platform.hasGnome ./desktop/gnome.nix
    ++ lib.optional config.platform.hasKDE ./desktop/kde.nix
    ++ lib.optional config.platform.isWSL ./wsl.nix;

  # ── Systemd user services ───────────────────────────────────────
  systemd.user.services = lib.mkIf config.platform.hasSystemd {
    # Add systemd user services here
  };

  # ── NVIDIA configuration ────────────────────────────────────────
  hardware.nvidia = lib.mkIf config.platform.hasNvidia {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
  };

  # ── AMD GPU configuration ───────────────────────────────────────
  hardware.amdgpu = lib.mkIf config.platform.hasAMD {
    enable = true;
  };
} 