# K3s server host configuration - VM-friendly defaults
{ config, pkgs, lib, ... }:
{
  imports = [
    ../../profiles/boot/uefi-sdboot.nix
  ];

  system.stateVersion = "24.11";
  networking.hostName = "k3s-01";
  networking.useDHCP = true;

  # Good defaults for Proxmox/QEMU disks by label
  fileSystems."/" = lib.mkDefault {
    device  = "/dev/disk/by-label/nixos";
    fsType  = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = lib.mkDefault {
    device  = "/dev/disk/by-label/EFI";
    fsType  = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Optional: add a local admin if you don't want only the 'ops' user from base
  # users.users.nbg = {
  #   isNormalUser = true; 
  #   extraGroups = [ "wheel" ];
  #   openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA...yourkey..." ];
  # };

  # K3s-specific optimizations
  boot.kernelParams = [
    # Optimize for containers
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

  # Increase file descriptor limits for Kubernetes
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 65536;
  };

  # Optional: add swap if needed (uncomment if you want swap)
  # swapDevices = [ { device = "/swapfile"; size = 2048; } ];
}
