# Infrastructure host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.11"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Disk layout (if using disko)
  disko.devices = (import ../../disko/infrastructure-01.nix { inherit lib; }).disko.devices;

  # Infrastructure-specific overrides
  services.nginx.virtualHosts."infra.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8080";  # Netbox
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."auth.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8081";  # Keycloak
      proxyWebsockets = true;
    };
  };

  # System-specific packages
  environment.systemPackages = with pkgs; [
    # Infrastructure-specific tools
    terraform
    ansible
    kubectl
    helm
  ];
}
