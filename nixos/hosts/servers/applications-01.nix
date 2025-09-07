# Applications host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.14"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Disk layout (if using disko)
  disko.devices = (import ../../disko/applications-01.nix).disko.devices;

  # Application-specific overrides
  services.nginx.virtualHosts."app.local" = {
    locations."/" = {
      proxyPass = "http://localhost:3000";  # Frontend
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."api.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8000";  # API
      proxyWebsockets = true;
    };
  };

  # Application-specific system packages
  environment.systemPackages = with pkgs; [
    # Application-specific tools
    docker-compose
    kubectl
    helm
  ];
}
