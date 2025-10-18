# Disko configuration for K3s VM - UEFI + ext4 root
{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00"; 
          size = "512MiB"; 
          priority = 1;
          content = {
            type = "filesystem"; 
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
            label = "EFI";
          };
        };
        root = {
          content = {
            type = "filesystem"; 
            format = "ext4";
            mountpoint = "/"; 
            mountOptions = [ "noatime" ];
            label = "nixos";
          };
        };
      };
    };
  };
}
