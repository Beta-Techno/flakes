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

  # Bootloader configuration for VM (UEFI + systemd-boot)
  imports = [ ../../profiles/boot/uefi-sdboot.nix ];

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
    # Netbox-specific tools (using container, not packaged version)
    postgresql_15
    pgcli
  ];
}
