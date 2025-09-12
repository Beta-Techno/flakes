{ config, pkgs, lib, ... }:

{
  imports = [
    # Pick the right boot profile for this VM/box
    ../../profiles/boot/uefi-sdboot.nix
    # or: ../../profiles/boot/bios-grub.nix
  ];

  system.stateVersion = "24.11";
  networking.useDHCP = true;

  # Ensure virtio drivers are in initrd for VMs
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
