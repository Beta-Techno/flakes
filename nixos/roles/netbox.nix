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
      DB_HOST = "localhost"; # now correct, because network=host
      DB_PORT = "5432";
      DB_NAME = "netbox";
      DB_USER = "netbox";
      DB_PASSWORD = "netbox123";
      REDIS_HOST = "localhost";
      REDIS_PORT = "6379";
      SECRET_KEY = "netbox-secret-key-change-me";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
      "--health-cmd=curl -f http://localhost:8080/health/ || exit 1"
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

  # Ensure PostgreSQL starts before NetBox container
  systemd.services.docker-netbox = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
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
