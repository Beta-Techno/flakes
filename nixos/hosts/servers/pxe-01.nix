{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/boot/uefi-sdboot.nix    # or bios-grub.nix if this box is legacy BIOS
    ../../roles/pxe-lite.nix
  ];

  system.stateVersion = "24.11";

  # Keep networking simple for the first pass
  networking.useDHCP = true;

  # Optional: make sure nginx answers on this name on your LAN DNS
  networking.hostName = "pxe-01";

  # If this is a VM, ensure virtio modules are present early
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];
}
