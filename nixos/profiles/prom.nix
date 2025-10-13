# Prometheus monitoring profile
{ config, pkgs, lib, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090;
    
    # Global configuration
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    # Scrape configurations
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
        }];
      }
      {
        job_name = "loki";
        static_configs = [{
          targets = [ "localhost:3100" ];
        }];
        metrics_path = "/metrics";
      }
      {
        job_name = "node-exporter";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
      {
        job_name = "nginx-exporter";
        static_configs = [{
          targets = [ "localhost:9113" ];
        }];
      }
      # Only if Postgres is actually enabled on this host
      (lib.mkIf config.services.postgresql.enable {
        job_name = "postgres-exporter";
        static_configs = [{ targets = [ "localhost:9187" ]; }];
      })
    ];

    # Alerting rules (disabled for now - can be added later)
    # ruleFiles = [
    #   ./prometheus-alerts.yml
    # ];
  };

  # Node exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";
    enabledCollectors = [
      "systemd"
      "cpu"
      "disk"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "processes"
    ];
  };

  # Nginx exporter for web server metrics
  services.prometheus.exporters.nginx = {
    enable = true;
    port = 9113;
    scrapeUri = "http://localhost/nginx_status";
  };

  # PostgreSQL exporter for database metrics
  services.prometheus.exporters.postgres = lib.mkIf config.services.postgresql.enable {
    enable = true;
    port = 9187;
    dataSourceNames = [ "postgresql://postgres@localhost/postgres?sslmode=disable" ];
  };

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    9090  # Prometheus
    9100  # Node exporter
    9113  # Nginx exporter
  ] ++ lib.optionals config.services.postgresql.enable [
    9187  # PostgreSQL exporter
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    prometheus
    prometheus-alertmanager
  ];
}
