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

  # Host-side directories for mounts + backups
  systemd.tmpfiles.rules = [
    "d /var/lib/netbox 0700 root root -"
    "d /var/lib/netbox/media 0755 root root -"
    "d /var/lib/netbox/reports 0755 root root -"
    "d /var/lib/netbox/scripts 0755 root root -"
    "d /var/backups/netbox 0750 root root -"
    "d /var/lib/netbox-backup 0700 root root -"
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
    # Persist files that are NOT in the database
    volumes = [
      "/var/lib/netbox/media:/opt/netbox/netbox/media:rw"
      "/var/lib/netbox/reports:/opt/netbox/netbox/reports:rw"
      "/var/lib/netbox/scripts:/opt/netbox/netbox/scripts:rw"
    ];
    
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

  # ────────────────────────────── Backups ─────────────────────────────────────
  # One-time: generate SSH keypair used to push backups to storage-01
  systemd.services.netbox-backup-keygen = {
    description = "Generate SSH key for NetBox backups";
    wantedBy = [ "multi-user.target" ];
    before = [ "netbox-backup.timer" ];
    serviceConfig = { Type = "oneshot"; };
    script = ''
      set -e
      install -d -m 0700 /var/lib/netbox-backup
      if [ ! -f /var/lib/netbox-backup/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /var/lib/netbox-backup/id_ed25519
        echo "=== NetBox backup public key (add this to backup@storage-01) ==="
        cat /var/lib/netbox-backup/id_ed25519.pub
      fi
      chmod 600 /var/lib/netbox-backup/id_ed25519
    '';
  };

  systemd.services.netbox-backup = {
    description = "NetBox daily backup → storage-01";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "30min";
    };
    # Minimal PATH for all tools we call
    environment.PATH =
      lib.makeBinPath [ pkgs.coreutils pkgs.util-linux pkgs.bash pkgs.openssh
                        pkgs.postgresql_15 pkgs.tar pkgs.zstd pkgs.rsync
                        pkgs.docker pkgs.jq ];
    script = ''
      set -euo pipefail
      BACKUP_ROOT=/var/backups/netbox
      TS=$(date -u +%Y%m%dT%H%M%SZ)
      HOST=$(hostname)
      STAMP_DIR="$BACKUP_ROOT/$TS"
      mkdir -p "$STAMP_DIR"

      # 1) Database dump (custom format; best for pg_restore)
      export PGPASSWORD=netbox123
      pg_dump -h 127.0.0.1 -U netbox -d netbox -Fc -f "$STAMP_DIR/netbox.pgsql.dump"
      unset PGPASSWORD

      # 2) Media and reports (best effort)
      if [ -d /var/lib/netbox/media ];   then tar -C /var/lib/netbox -cf "$STAMP_DIR/media.tar"   media; fi
      if [ -d /var/lib/netbox/reports ]; then tar -C /var/lib/netbox -cf "$STAMP_DIR/reports.tar" reports || true; fi
      [ -f /var/lib/netbox/secret-key ] && cp /var/lib/netbox/secret-key "$STAMP_DIR/secret-key"

      # 3) Container image tag (traceability)
      docker inspect netbox 2>/dev/null | jq -r '.[0].Config.Image // empty' > "$STAMP_DIR/image.txt" || true

      # 4) Manifest
      cat > "$STAMP_DIR/manifest.json" <<JSON
      { "host":"$HOST","timestamp":"$TS","db_format":"pg_dump -Fc","has_media":$( [ -f "$STAMP_DIR/media.tar" ] && echo true || echo false ) }
JSON

      # 5) Compress tars (faster transfer)
      for t in media.tar reports.tar; do
        [ -f "$STAMP_DIR/$t" ] && zstd -19 --rm "$STAMP_DIR/$t"
      done

      # 6) Push to storage-01 via rsync+ssh
      DEST="backup@storage-01:/var/storage/backups/netbox/$HOST/$TS/"
      SSH="ssh -i /var/lib/netbox-backup/id_ed25519 -o StrictHostKeyChecking=accept-new"
      rsync -az --chmod=Fu=rw,Fg=r,Do=r --delete -e "$SSH" "$STAMP_DIR/" "$DEST"

      # Convenience: update local "latest" symlink
      ln -sfn "$STAMP_DIR" "$BACKUP_ROOT/latest"
    '';
  };

  systemd.timers.netbox-backup = {
    description = "Schedule NetBox backups";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:30";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  # Prune local copies older than 14 days (remote retention is your policy)
  systemd.services.netbox-backup-prune = {
    description = "Prune old local NetBox backups";
    serviceConfig.Type = "oneshot";
    script = ''
      find /var/backups/netbox -maxdepth 1 -type d -name "20????????T??????Z" -mtime +14 -print -exec rm -rf {} +
    '';
  };
  systemd.timers.netbox-backup-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
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
    
    # Backup tools
    rsync
    zstd
    jq
    
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
