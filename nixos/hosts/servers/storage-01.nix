# Storage server host configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ../../profiles/boot/uefi-sdboot.nix
    ../../roles/storage-server.nix
  ];

  system.stateVersion = "24.11";

  # Network configuration
  networking.useDHCP = true;
  networking.hostName = "storage-01";

  # Filesystems - allocate more space for storage
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # If this is a VM, ensure virtio modules are present early
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  # Admin user
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "backup" ];
    shell = pkgs.zsh;
    initialPassword = "TempPass1@3$";
  };
  programs.zsh.enable = true;

  # System-specific packages for storage management
  environment.systemPackages = with pkgs; [
    # Storage monitoring
    dfc
    ncdu
    tree
    
    # Network tools
    nmap
    tcpdump
    wireshark-cli
  ];
}
