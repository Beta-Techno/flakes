# Netbox host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.10"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Disk layout (if using disko)
  disko.devices = import ../../disko/netbox-01.nix;

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
