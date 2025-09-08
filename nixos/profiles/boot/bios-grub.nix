# BIOS GRUB boot profile for Proxmox VMs
{ lib, ... }:
{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;

    grub = {
      enable = true;
      # Modern option is `devices` (preferred over deprecated `device`)
      devices = [ "/dev/sda" ];  # adjust to vda if your disk is virtio
      useOSProber = false;
    };
  };
}
