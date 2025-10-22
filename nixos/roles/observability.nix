# Dedicated observability role - owns Prometheus/Loki/Grafana stack
{ config, lib, pkgs, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
    ../profiles/prom.nix
    ../profiles/loki.nix
    ../profiles/grafana.nix
    ../profiles/sops.nix
    ../profiles/nvim-tiny-plugins.nix
    ../profiles/observability/prometheus-inventory-sd.nix
  ];

  # One friendly vhost for observability services
  services.nginx.virtualHosts."observability.local" = {
    default = true;
    locations."/" = { 
      proxyPass = "http://127.0.0.1:3000"; 
      proxyWebsockets = true; 
    };
    locations."/prometheus/" = { 
      proxyPass = "http://127.0.0.1:9090/"; 
      proxyWebsockets = true; 
    };
    locations."/nginx_status".extraConfig = ''
      stub_status;
      allow 127.0.0.1;
      deny all;
    '';
  };

  # Blackbox exporter for synthetic monitoring
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9115;
    configFile = {
      modules = {
        http_2xx = { prober = "http"; timeout = "5s"; http.preferred_ip_protocol = "ip4"; };
        icmp     = { prober = "icmp"; };
      };
    };
  };

  # Add blackbox HTTP probes to Prometheus scrape configs
  services.prometheus.scrapeConfigs = lib.mkAfter [
    {
      job_name = "blackbox_http";
      metrics_path = "/probe";
      params.module = [ "http_2xx" ];
      static_configs = [{ targets = [
        "http://observability.local"
        "http://media.local"
        "http://stream.local"
      ]; }];
      relabel_configs = [
        { source_labels = [ "__address__" ]; target_label = "__param_target"; }
        { source_labels = [ "__param_target" ]; target_label = "instance"; }
        { target_label = "__address__"; replacement = "127.0.0.1:9115"; }
      ];
    }
  ];

  # Open only what this node actually needs
  networking.firewall.allowedTCPPorts = lib.mkAfter [ 80 443 9090 9093 3000 3100 9115 ];

  # System packages for observability management
  environment.systemPackages = with pkgs; [
    # Monitoring tools
    htop
    iotop
    smartmontools
    
    # Network tools
    nmap
    tcpdump
    
    # Docker tools (if needed for containerized monitoring)
    docker-compose
  ];
}
