# Netbox role - dedicated IPAM/DCIM server
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/postgres.nix
    # Bootloader is hardware-specific; pick it in the host file
  ];

  # Netbox-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    8080  # Netbox
    5432  # PostgreSQL
  ];

  # Enable Docker for Netbox container
  virtualisation.docker.enable = true;
  users.users.root.extraGroups = [ "docker" ];

  # Enable Redis for NetBox
  services.redis.enable = true;

  # Create /var/lib/netbox for secrets/env
  systemd.tmpfiles.rules = [
    "d /var/lib/netbox 0700 root root -"
  ];

  # One-shot unit that creates a stable SECRET_KEY once
  systemd.services.netbox-secrets = {
    description = "Generate NetBox SECRET_KEY and env file";
    after = [ "local-fs.target" ];
    before = [ "docker-netbox.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "netbox-gen-secret" ''
        set -euo pipefail
        install -d -m 0700 /var/lib/netbox
        if [ ! -s /var/lib/netbox/secret-key ]; then
          # 64-char alphanumeric (Django requires >=50 chars)
          head -c 512 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64 > /var/lib/netbox/secret-key
          chmod 600 /var/lib/netbox/secret-key
        fi
        # Write env-file that oci-containers will read
        printf "SECRET_KEY=%s\n" "$(tr -d '\n' </var/lib/netbox/secret-key)" > /var/lib/netbox/env
        chmod 600 /var/lib/netbox/env
      ''}";
      RemainAfterExit = true;
    };
  };

  # Netbox container
  virtualisation.oci-containers.containers.netbox = {
    image = "netboxcommunity/netbox:v4.3.7";
    # Using host networking; container binds directly to host ports
    # (so no need for explicit port mappings)
    
    environmentFiles = [ "/var/lib/netbox/env" ];
    environment = {
      TZ = "UTC";

      # Postgres
      DB_HOST = "127.0.0.1";
      DB_PORT = "5432";
      DB_NAME = "netbox";
      DB_USER = "netbox";
      DB_PASSWORD = "netbox123";

      # Make SSL intent explicit (you disabled server SSL)
      DB_SSLMODE = "disable";

      # Redis
      REDIS_HOST = "127.0.0.1";
      REDIS_PORT = "6379";
      # REDIS_PASSWORD = "";   # uncomment if you later add a password

      # NetBox/Django - allow everything (trusted internal network)
      ALLOWED_HOSTS = "*";

      # CORS configuration for cross-origin requests
      CORS_ALLOWED_ORIGINS = "*";
      CORS_ALLOW_CREDENTIALS = "true";
      CORS_ALLOW_ALL_ORIGINS = "true";

      # Diagnostics
      DB_WAIT_DEBUG = "1";
      DB_WAIT_TIMEOUT = "90";
    };
    
    extraOptions = [
      "--network=host"
      # Healthcheck using the correct NetBox endpoint:
      "--health-cmd=python -c 'import urllib.request,sys; sys.exit(0 if urllib.request.urlopen(\"http://127.0.0.1:8080/api/status/\").status==200 else 1)'"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=3"
    ];
  };

  # Create Netbox database
  services.postgresql.ensureDatabases = [ "netbox" ];
  services.postgresql.ensureUsers = [
    {
      name = "netbox";
      ensureDBOwnership = true;
    }
  ];

  # Use SCRAM for passwords and require it on localhost (modern default)
  services.postgresql.settings = {
    password_encryption = "scram-sha-256";
    listen_addresses = lib.mkForce "localhost";  # Force localhost to resolve any conflicts
  };
  services.postgresql.authentication = lib.mkForce ''
    # TYPE  DATABASE  USER  ADDRESS         METHOD
    local   all       all                   trust
    host    all       all   127.0.0.1/32    scram-sha-256
    host    all       all   ::1/128         scram-sha-256
  '';

  # 1) First-time init (runs only when the cluster is initially created)
  services.postgresql.initialScript = pkgs.writeText "netbox-init.sql" ''
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'netbox') THEN
        CREATE ROLE netbox LOGIN;
      END IF;
      -- Set password to match container env
      ALTER ROLE netbox WITH PASSWORD 'netbox123';
    END
    $$;
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'netbox') THEN
        CREATE DATABASE netbox OWNER netbox;
      END IF;
    END
    $$;
  '';

  # 2) Every boot, ensure the password matches the env (idempotent)
  systemd.services.set-netbox-db-password = {
    description = "Ensure netbox DB user has the expected password";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = "${pkgs.postgresql_15}/bin/psql -tAc \"ALTER ROLE netbox WITH PASSWORD 'netbox123';\"";
    };
  };

  # Ensure NetBox PostgreSQL extensions are created
  systemd.services.netbox-db-extensions = {
    description = "Ensure NetBox PostgreSQL extensions";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; User = "postgres"; };
    script = ''
      set -e
      ${pkgs.postgresql_15}/bin/psql -v ON_ERROR_STOP=1 -d netbox -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
      ${pkgs.postgresql_15}/bin/psql -v ON_ERROR_STOP=1 -d netbox -c "CREATE EXTENSION IF NOT EXISTS citext;"
    '';
  };

  # Ensure DB is ready and password is set BEFORE NetBox starts
  systemd.services.docker-netbox = {
    after = [
      "docker.service"
      "postgresql.service"
      "redis.service"
      "set-netbox-db-password.service"
      "netbox-db-extensions.service"
      "netbox-secrets.service"
    ];
    requires = [
      "docker.service"
      "postgresql.service"
      "redis.service"
      "set-netbox-db-password.service"
      "netbox-db-extensions.service"
      "netbox-secrets.service"
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      # Gate startup on a successful login using the same creds the container will use.
      ExecStartPre = "${pkgs.bash}/bin/sh -c 'PGPASSWORD=netbox123 ${pkgs.postgresql_15}/bin/pg_isready -h 127.0.0.1 -p 5432 -U netbox && PGPASSWORD=netbox123 ${pkgs.postgresql_15}/bin/psql -h 127.0.0.1 -U netbox -d netbox -c \"select 1\"'";
    };
  };

  # Nginx reverse proxy for Netbox
  services.nginx.virtualHosts."netbox.local" = {
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers for cross-origin requests
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight OPTIONS requests
        if ($request_method = 'OPTIONS') {
          add_header Access-Control-Allow-Origin "*";
          add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
          add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
          add_header Access-Control-Allow-Credentials "true";
          add_header Content-Length 0;
          add_header Content-Type text/plain;
          return 204;
        }
      '';
    };
  };

  # System packages for Netbox management
  environment.systemPackages = with pkgs; [
    # Database tools
    postgresql_15
    pgcli
    
    # Monitoring tools
    htop
    iotop
    
    # Network tools
    nmap
    tcpdump
    
    # Docker tools
    docker-compose
  ];
}
