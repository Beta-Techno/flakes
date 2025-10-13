# Grafana monitoring dashboard profile
{ config, pkgs, lib, ... }:

{
  services.grafana = {
    enable = true;
    port = 3000;
    
    # Basic configuration
    settings = {
      server = {
        http_port = 3000;
        domain = "grafana.local";
        root_url = "https://grafana.local/";
      };
      
      security = {
        admin_user = "admin";
        admin_password = "$__file{/var/lib/grafana/admin-password}";
        secret_key = "$__file{/var/lib/grafana/secret-key}";
      };
      
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/grafana.db";
      };
    };
    
    # Data sources configuration
    declarativePlugins = [ ];
    
    # Provisioning configuration
    provision = {
      datasources = {
        settings = {
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:9090";
              access = "proxy";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localhost:3100";
              access = "proxy";
            }
          ];
        };
      };
      
      dashboards = {
        settings = {
          providers = [
            {
              name = "default";
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = false;
              editable = true;
              options = {
                path = "/var/lib/grafana/dashboards";
              };
            }
          ];
        };
      };
    };
  };

  # Create dashboard directory
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana"
  ];

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    3000  # Grafana
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    grafana
  ];
}
