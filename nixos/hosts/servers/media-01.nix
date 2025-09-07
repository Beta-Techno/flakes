# Media host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.12"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Disk layout (if using disko)
  disko.devices = (import ../../disko/media-01.nix).disko.devices;

  # Media-specific overrides
  services.nginx.virtualHosts."media.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8096";  # Jellyfin
      proxyWebsockets = true;
    };
  };

  # Media-specific system packages
  environment.systemPackages = with pkgs; [
    # Media-specific tools
    handbrake
    makemkv
    vlc
  ];
}
