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

  # Netbox container
  virtualisation.oci-containers.containers.netbox = {
    image = "netboxcommunity/netbox:v4.3.7";
    # Using host networking; container binds directly to host ports
    # (so no need for explicit port mappings)
    
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

      # NetBox settings
      SECRET_KEY = "netbox-secret-key-change-me";
      # Include all names you'll hit:
      ALLOWED_HOSTS = "127.0.0.1,localhost,netbox.local";

      # Show full Python traceback for the "Waiting on DB…" loop:
      DB_WAIT_DEBUG = "1";
      # (optional) extend wait so you can read it:
      DB_WAIT_TIMEOUT = "90";
    };
    
    extraOptions = [
      "--network=host"
      # Healthcheck without curl, runs inside the container:
      "--health-cmd=python -c 'import urllib.request,sys; sys.exit(0 if urllib.request.urlopen(\"http://127.0.0.1:8080/health/\").status==200 else 1)'"
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
    ];
    requires = [
      "docker.service"
      "postgresql.service"
      "redis.service"
      "set-netbox-db-password.service"
      "netbox-db-extensions.service"
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
