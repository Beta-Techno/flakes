# Netbox host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.10"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # File systems for VM (like nick-vm)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";  # Use label-based mounting (more flexible)
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Bootloader: Proxmox handles boot directly from disk (like nick-vm)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;  # Disable grub as well
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.efi.efiSysMountPoint = lib.mkForce null;  # Don't try to mount /boot 
  
  # Disable bootloader requirement for VM environment
  # Proxmox handles boot directly from disk
  boot.loader.grub.devices = lib.mkForce [ ];  # Empty list disables grub requirement

  # Pin system state version
  system.stateVersion = "24.11";

  # Netbox-specific overrides
  services.nginx.virtualHosts."netbox.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
    };
  };

  # System-specific packages
  environment.systemPackages = with pkgs; [
    # Netbox-specific tools
    netbox
    postgresql_15
    pgcli
  ];
}
