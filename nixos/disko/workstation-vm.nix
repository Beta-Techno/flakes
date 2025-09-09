# nixos/disko/workstation-vm.nix
{ lib, ... }:
{
  # If your VM disk is virtio-blk (not virtio-scsi), change /dev/sda -> /dev/vda.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "512MiB";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
            extraArgs = [ "-n" "EFI" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
            extraArgs = [ "-L" "nixos" ];
          };
        };
      };
    };
  };
}
