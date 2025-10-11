{ config, pkgs, lib, ... }:
{
  imports = [ ../../profiles/boot/uefi-sdboot.nix ];
  system.stateVersion = "24.11";
  networking.useDHCP = true;

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  fileSystems."/" = lib.mkDefault { device="/dev/disk/by-label/nixos"; fsType="ext4"; options=[ "noatime" ]; };
  fileSystems."/boot" = lib.mkDefault { device="/dev/disk/by-label/EFI"; fsType="vfat"; options=[ "fmask=0077" "dmask=0077" ]; };

  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    initialPassword = "TempPass1@3$";
  };
  programs.zsh.enable = true;
}
