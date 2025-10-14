# Grafana monitoring dashboard profile
{ config, pkgs, lib, ... }:

{
  services.grafana = {
    enable = true;
    provision.enable = true;
    
    # Basic configuration
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";  # Bind to all interfaces for external access
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
      
      paths = {
        plugins = "/var/lib/grafana/plugins";
      };
      
      # Allow unsigned plugin via grafana.ini (preferred over env var)
      plugins = {
        # Comma-separated list if you add more later
        allow_loading_unsigned_plugins = "grafana-bigquery-datasource";
      };
    };
    
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
            {
              name = "BigQuery";
              type = "grafana-bigquery-datasource";
              access = "proxy";
              jsonData = {
                authenticationType = "jwt";
                tokenUri = "https://oauth2.googleapis.com/token";
                # Optional: project override; plugin can infer from key
                # defaultProject = "my-gcp-project";
              };
              secureJsonData = {
                # Service account JSON provided via SOPS
                privateKey = "$__file{${config.sops.secrets."gcp-bq-sa.json".path}}";
              };
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

  # Put GF_* variables on the systemd unit so Grafana downloads the plugin
  systemd.services.grafana.environment = {
    # Let Grafana use the latest available version
    GF_INSTALL_PLUGINS = "grafana-bigquery-datasource";
    # (no need to set GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS here since
    #  we configured it in grafana.ini above via settings.plugins.allow_loading_unsigned_plugins)
  };

  # Ensure plugin dir exists and is writable by grafana
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/plugins 0755 grafana grafana -"
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    3000  # Grafana
  ];
}
