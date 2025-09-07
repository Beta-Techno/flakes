# Utility functions for NixOS configuration
{ lib, pkgs, ... }:

rec {
  # Create a systemd service for OCI containers
  mkContainerService = name: config: {
    virtualisation.oci-containers.containers.${name} = config;
  };

  # Create a reverse proxy configuration
  mkReverseProxy = hostname: upstream: {
    services.nginx.virtualHosts.${hostname} = {
      locations."/" = {
        proxyPass = upstream;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # Create a database with user and database
  mkDatabase = dbName: userName: {
    services.postgresql.ensureDatabases = [ dbName ];
    services.postgresql.ensureUsers = [
      {
        name = userName;
        ensureDBOwnership = true;
      }
    ];
  };

  # Create a backup configuration
  mkBackup = name: source: destination: {
    systemd.timers."backup-${name}" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    systemd.services."backup-${name}" = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.rsync}/bin/rsync -av --delete ${source} ${destination}
      '';
    };
  };

  # Create a monitoring exporter
  mkExporter = name: port: config: {
    services.prometheus.exporters.${name} = {
      enable = true;
      port = port;
    } // config;
  };
}
