# UEFI systemd-boot profile for real UEFI machines
{ lib, ... }:
{
  boot.loader = {
    grub.enable = lib.mkForce false;

    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
}
