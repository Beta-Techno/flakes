{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/boot/uefi-sdboot.nix    # or bios-grub.nix if this box is legacy BIOS
  ];

  system.stateVersion = "24.11";

  # Keep networking simple for the first pass
  networking.useDHCP = true;

  # Optional: make sure nginx answers on this name on your LAN DNS
  networking.hostName = "pxe-01";

  # If this is a VM, ensure virtio modules are present early
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  # If you used the disko labels from your scripts
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

  # Convenience admin user (adjust to your policy)
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    initialPassword = "TempPass1@3$";  # change on first login
  };
  programs.zsh.enable = true;
}
