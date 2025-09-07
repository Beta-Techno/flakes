# Infrastructure role - bundles infrastructure services
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/cloudflared-system.nix
    ../profiles/prom.nix
    ../profiles/loki.nix
    ../profiles/grafana.nix
    ../services/infrastructure/netbox/default.nix
    ../services/infrastructure/keycloak/default.nix
  ];

  # Infrastructure-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    8080  # Netbox
    8081  # Keycloak
    9090  # Prometheus
    3000  # Grafana
  ];

  # Shared storage for infrastructure services
  fileSystems."/var/lib/infrastructure" = {
    device = "/dev/disk/by-label/infrastructure";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # System packages for infrastructure management
  environment.systemPackages = with pkgs; [
    # Infrastructure tools
    netbox
    keycloak
    prometheus
    grafana
    
    # Monitoring tools
    htop
    iotop
    smartmontools
    
    # Network tools
    nmap
    tcpdump
    wireshark-cli
  ];
}
