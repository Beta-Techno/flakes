# Grafana monitoring dashboard profile
{ config, pkgs, lib, ... }:

let
  # Keep dashboards as plain JSON under version control; Nix will copy to the store.
  dashboardsDir = ../../observability/dashboards;
in
{
  services.grafana = {
    enable = true;
    provision.enable = true;
    
    # Basic configuration
    settings = {
      server = {
        http_port = lib.mkDefault 3000;
        http_addr = lib.mkDefault "0.0.0.0";  # Bind to all interfaces for external access
        domain    = lib.mkDefault "grafana.local";
        root_url  = lib.mkDefault "http://grafana.local/";
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
          uid = "PROM";
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          access = "proxy";
          isDefault = true;
        }
        {
          uid = "LOKI";
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
          access = "proxy";
        }
        {
          uid = "BQ";
          name = "BigQuery";
          type = "grafana-bigquery-datasource";
          access = "proxy";
          jsonData = {
            authenticationType = "jwt";
            defaultProject = "bigquery-475119";
            clientEmail = "bigquery-drive-audit@bigquery-475119.iam.gserviceaccount.com";
            tokenUri = "https://oauth2.googleapis.com/token";
            processingLocation = "US";
            privateKeyPath = "${config.sops.secrets."gcp-bq-sa.pem".path}";
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
              # Point straight at the Nix store path for your JSON files
              options = {
                path = "${dashboardsDir}";
              };
            }
          ];
        };
      };
    };
  };

  # Put GF_* variables on the systemd unit so Grafana downloads the plugin
  systemd.services.grafana = {
    # Bring up networking first (Grafana calls out to fetch plugins, etc.)
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # Start only if the SA JSON secret exists (written by sops-nix)
    unitConfig.ConditionPathExists = "/var/lib/grafana/gcp-bq-sa.json";
    environment = {
      # Let Grafana use the latest available version
      GF_INSTALL_PLUGINS = "grafana-bigquery-datasource";
      # (no need to set GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS here since
      #  we configured it in grafana.ini above via settings.plugins.allow_loading_unsigned_plugins)
    };
  };

  # Ensure plugin dir exists and is writable by grafana
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/plugins 0755 grafana grafana -"
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];

  # Restart Grafana only when dashboard content changes
  systemd.services.grafana.restartTriggers = [ dashboardsDir ];

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    3000  # Grafana
  ];
}
