# Infrastructure role - monitoring and observability
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/prom.nix
    ../profiles/loki.nix
    ../profiles/grafana.nix
    ../profiles/sops.nix
  ];

  # Infrastructure-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    9090  # Prometheus
    3000  # Grafana
    3100  # Loki
  ];

  # Enable Docker for containerized services
  virtualisation.docker.enable = true;
  users.users.root.extraGroups = [ "docker" ];

  # Nginx reverse proxy for monitoring services
  services.nginx.virtualHosts."monitoring.local" = {
    locations."/" = {
      proxyPass = "http://localhost:3000";  # Grafana
      proxyWebsockets = true;
    };
    locations."/prometheus/" = {
      proxyPass = "http://localhost:9090/";
      proxyWebsockets = true;
    };
    # If the host didn't define a stub_status, provide one here
    locations."/nginx_status".extraConfig = lib.mkDefault ''
      stub_status;
      allow 127.0.0.1;
      deny all;
    '';
  };

  # System packages for infrastructure management
  environment.systemPackages = with pkgs; [
    # Monitoring tools
    htop
    iotop
    smartmontools
    
    # Network tools
    nmap
    tcpdump
    
    # Docker tools
    docker-compose
  ];
}
