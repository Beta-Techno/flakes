# Netbox role - dedicated IPAM/DCIM server
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/postgres.nix
    ../profiles/sops.nix
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

  # Create NetBox system user for SOPS secret ownership
  users.groups.netbox = { };
  users.users.netbox = {
    isSystemUser = true;
    group = "netbox";
    home = "/var/lib/netbox";
  };

  # Enable Redis for NetBox (named instance) – expose TCP on localhost:6379
  services.redis.servers.netbox = {
    enable = true;
    # use first-class option to avoid conflicts with the module's computed settings
    port = 6379;
    # keep bind local-only; either keep it in settings or use the top-level option.
    settings = {
      bind = "127.0.0.1";
      # optional hardening:
      # "protected-mode" = "yes";
    };
    # Alternatively (equivalent), you can write:
    # bind = [ "127.0.0.1" ];
  };

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
        
        # Build /var/lib/netbox/env fresh each boot so it always has the latest secrets
        {
          printf "SECRET_KEY=%s\n" "$(tr -d '\n' </var/lib/netbox/secret-key)"
          
          # Postgres password from SOPS
          if [ -r ${config.sops.secrets.postgres-password.path} ]; then
            printf "DB_PASSWORD=%s\n" "$(tr -d '\n' < ${config.sops.secrets.postgres-password.path})"
          fi
          
          # Wait up to 60s for admin password (first boot ordering can make this arrive a hair late)
          for i in $(seq 1 60); do
            if [ -r ${config.sops.secrets.netbox-admin-password.path} ]; then
              printf "SUPERUSER_PASSWORD=%s\n" "$(tr -d '\n' < ${config.sops.secrets.netbox-admin-password.path})"
              break
            fi
            sleep 1
          done
        } > /var/lib/netbox/env
        
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
      # DB_PASSWORD injected via /var/lib/netbox/env (netbox-secrets service)

      # Make SSL intent explicit (you disabled server SSL)
      DB_SSLMODE = "disable";

      # Redis
      REDIS_HOST = "127.0.0.1";
      REDIS_PORT = "6379";
      # REDIS_PASSWORD = "";   # uncomment if you later add a password

      # NetBox/Django
      ALLOWED_HOSTS = "*";                 # dev only; set real hostnames in prod
      # CORS (NetBox reads the *ORIGIN* names)
      CORS_ORIGIN_ALLOW_ALL = "true";      # dev: allow any Origin
      CORS_ALLOW_CREDENTIALS = "false";    # keep false if you use token auth
      # For production, prefer an explicit allow‑list instead of the line above:
      # CORS_ORIGIN_WHITELIST = "https://build.example.com,https://tele.example.com"
      # (comma‑separated list of scheme+host(+port))

      # Create a superuser on first boot (NetBox Docker supports these)
      SUPERUSER_NAME = "admin";
      SUPERUSER_EMAIL = "admin@example.com";
      # SUPERUSER_PASSWORD will be appended to the env file by netbox-secrets

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
      -- Password will be set by set-netbox-db-password service
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
    serviceConfig = { Type = "oneshot"; User = "postgres"; };
    script = ''
      set -euo pipefail

      # 1) Read secret and strip newline
      PW="$(${pkgs.coreutils}/bin/tr -d '\n' < ${config.sops.secrets.postgres-password.path})"

      # 2) SQL-escape any single quotes by doubling them (using octal escapes to avoid Nix parser issues)
      PW_ESC="$(${pkgs.coreutils}/bin/printf "%s" "$PW" | ${pkgs.gnused}/bin/sed "s/'/\047\047/g")"

      # 3) Apply password (ON_ERROR_STOP at psql level)
      ${pkgs.postgresql_15}/bin/psql -v ON_ERROR_STOP=1 -d postgres \
        -c "ALTER ROLE netbox WITH PASSWORD '$PW_ESC';"
    '';
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
      "redis-netbox.service"
      "set-netbox-db-password.service"
      "netbox-db-extensions.service"
      "netbox-secrets.service"
    ];
    requires = [
      "docker.service"
      "postgresql.service"
      "redis-netbox.service"
      "set-netbox-db-password.service"
      "netbox-db-extensions.service"
      "netbox-secrets.service"
    ];
    wantedBy = [ "multi-user.target" ];
    # Make the unit see DB_PASSWORD and SECRET_KEY from the same env-file
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      EnvironmentFile = "/var/lib/netbox/env";
    };

    # High-level hook that systemd turns into ExecStartPre=
    preStart = let
      pg_isready = "${pkgs.postgresql_15}/bin/pg_isready";
      psql      = "${pkgs.postgresql_15}/bin/psql";
    in ''
      set -euo pipefail
      # Ensure the env file exists (netbox-secrets.service writes it)
      test -r /var/lib/netbox/env
      # Use the same password the container will use
      export PGPASSWORD="$DB_PASSWORD"
      # Wait until Postgres is accepting connections for netbox
      ${pg_isready} -h 127.0.0.1 -p 5432 -U netbox
      # Prove credentials work
      ${psql} -h 127.0.0.1 -U netbox -d netbox -c 'select 1'
    '';
  };

  # ────────────────────────────── Backups ─────────────────────────────────────
  # Setup SSH keypair from SOPS for NetBox backups
  systemd.services.netbox-backup-keygen = {
    description = "Setup SSH key for NetBox backups from SOPS";
    wantedBy = [ "multi-user.target" ];
    before = [ "netbox-backup.timer" ];
    serviceConfig = { Type = "oneshot"; };
    script = ''
      set -e
      install -d -m 0700 /var/lib/netbox-backup
      # Copy private key from SOPS to backup location
      cp ${config.sops.secrets.netbox-backup-private-key.path} /var/lib/netbox-backup/id_ed25519
      chmod 600 /var/lib/netbox-backup/id_ed25519
      # Generate public key from private key
      ${pkgs.openssh}/bin/ssh-keygen -y -f /var/lib/netbox-backup/id_ed25519 > /var/lib/netbox-backup/id_ed25519.pub
      chmod 644 /var/lib/netbox-backup/id_ed25519.pub
    '';
  };

  # Seed and pin known_hosts for the backup user (one‑shot, idempotent)
  systemd.services.netbox-backup-knownhosts = {
    description = "Seed known_hosts for NetBox backup SSH";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; };
    script = ''
      set -euo pipefail
      install -d -m 0700 /var/lib/netbox-backup
      # Seed by hostname only; avoids IP drift after VM changes
      ${pkgs.openssh}/bin/ssh-keyscan -T 5 -t ed25519 storage-01 2>/dev/null | sort -u > /var/lib/netbox-backup/known_hosts.new
      install -m 0644 /var/lib/netbox-backup/known_hosts.new /var/lib/netbox-backup/known_hosts
      rm -f /var/lib/netbox-backup/known_hosts.new
    '';
  };

  systemd.services.netbox-backup = {
    description = "NetBox daily backup → storage-01";
    after = [
      "network-online.target"
      "netbox-backup-keygen.service"
      "netbox-backup-knownhosts.service"
    ];
    wants = [ "network-online.target" "netbox-backup-keygen.service" "netbox-backup-knownhosts.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "30min";
    };
    # Let NixOS compose PATH correctly for the script
    path = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.inetutils         # <- provides `hostname`
      pkgs.bash
      pkgs.openssh
      pkgs.postgresql_15
      pkgs.gnutar
      pkgs.zstd
      pkgs.rsync
      pkgs.docker
      pkgs.jq
    ];
    script = ''
      set -euo pipefail
      BACKUP_ROOT=/var/backups/netbox
      TS=$(date -u +%Y%m%dT%H%M%SZ)
      HOST=$(hostname)
      STAMP_DIR="$BACKUP_ROOT/$TS"
      mkdir -p "$STAMP_DIR"

      # 1) Database dump (custom format; best for pg_restore)
      PW="$(tr -d '\n' < ${config.sops.secrets.postgres-password.path})"
      PGPASSWORD="$PW" pg_dump -h 127.0.0.1 -U netbox -d netbox -Fc -f "$STAMP_DIR/netbox.pgsql.dump"
      unset PW

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
      SSH="ssh -i /var/lib/netbox-backup/id_ed25519 \
           -o IdentitiesOnly=yes \
           -o UserKnownHostsFile=/var/lib/netbox-backup/known_hosts \
           -o StrictHostKeyChecking=yes"

      DEST="backup@storage-01:/var/storage/backups/netbox/$HOST/$TS/"

      # NOTE: --mkpath makes the remote parents automatically
      rsync -az --mkpath --chmod=Fu=rw,Fg=r,Do=r --delete \
        -e "$SSH" "$STAMP_DIR/" "$DEST"

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

  # ────────────────────────────── Restore ─────────────────────────────────────
  # Instance unit: call with `systemctl start 'netbox-restore@<TIMESTAMP>'`
  #
  # Why instance?
  # - systemd does not pass "service arguments" via `--`.
  # - `%i` (instance) is the standard pattern for dynamic parameters.
  systemd.services."netbox-restore@" = let
    restoreScript = pkgs.writeShellScript "netbox-restore" ''
      set -euo pipefail

      # Timestamp comes from systemd instance: netbox-restore@<TS>
      TS="''${TS?missing TS}"

      # Use explicit tool paths to avoid PATH surprises
      HOST="$(${pkgs.inetutils}/bin/hostname)"
      BACKUP_ROOT_REMOTE="/var/storage/backups/netbox/$HOST/$TS"
      TMP="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap 'rm -rf "$TMP"' EXIT

      echo "→ Fetching backup set $BACKUP_ROOT_REMOTE from storage-01"
      SSH="${pkgs.openssh}/bin/ssh -i /var/lib/netbox-backup/id_ed25519 \
           -o IdentitiesOnly=yes \
           -o UserKnownHostsFile=/var/lib/netbox-backup/known_hosts \
           -o StrictHostKeyChecking=yes"

      ${pkgs.rsync}/bin/rsync -az -e "$SSH" "backup@storage-01:$BACKUP_ROOT_REMOTE/" "$TMP/"
      test -s "$TMP/netbox.pgsql.dump" || { echo "Missing DB dump"; exit 1; }

      echo "→ Stopping NetBox container"
      ${pkgs.systemd}/bin/systemctl stop docker-netbox.service || true

      echo "→ Ensuring PostgreSQL is running"
      ${pkgs.systemd}/bin/systemctl start postgresql.service

      echo "→ Dropping and recreating database"
      sudo -u postgres ${pkgs.postgresql_15}/bin/psql -v ON_ERROR_STOP=1 -d postgres <<'SQL'
      SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'netbox';
      DROP DATABASE IF EXISTS netbox;
      CREATE DATABASE netbox OWNER netbox;
SQL

      echo "→ Restoring database (pg_restore -Fc)"
      export PGPASSWORD="$(${pkgs.coreutils}/bin/tr -d '\n' < ${config.sops.secrets.postgres-password.path})"
      ${pkgs.postgresql_15}/bin/pg_restore \
        -h 127.0.0.1 -U netbox -d netbox \
        --no-owner --no-privileges "$TMP/netbox.pgsql.dump"

      echo "→ Restoring media and reports (if present)"
      [ -f "$TMP/media.tar.zst" ]   && ${pkgs.zstd}/bin/zstd -d -c "$TMP/media.tar.zst"   | ${pkgs.gnutar}/bin/tar -C /var/lib/netbox -xf -
      [ -f "$TMP/reports.tar.zst" ] && ${pkgs.zstd}/bin/zstd -d -c "$TMP/reports.tar.zst" | ${pkgs.gnutar}/bin/tar -C /var/lib/netbox -xf -
      chown -R root:root /var/lib/netbox/media /var/lib/netbox/reports 2>/dev/null || true

      echo "→ Restoring SECRET_KEY (if present)"
      if [ -f "$TMP/secret-key" ]; then
        install -m 0600 "$TMP/secret-key" /var/lib/netbox/secret-key
      fi

      if [ -s "$TMP/image.txt" ]; then
        echo "→ Backup was taken from image: $(cat "$TMP/image.txt")"
      fi

      echo "→ Starting NetBox container"
      ${pkgs.systemd}/bin/systemctl start docker-netbox.service

      echo "→ Restore complete. Health probe:"
      ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8080/api/status/ >/dev/null && echo "✓ API healthy"
    '';
  in {
    description = "Restore NetBox from backup timestamp %I";
    after = [
      "network-online.target"
      "postgresql.service"
    ];
    wants = [
      "network-online.target"
      "postgresql.service"
      "netbox-backup-keygen.service"
      "netbox-backup-knownhosts.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "60min";
      # Pass the instance (%i) to the script via env TS=...
      ExecStart = lib.mkForce [ "${pkgs.bash}/bin/bash" "-c" "TS=%i exec ${restoreScript}" ];
    };
    # Make sure all tools used in the script are on PATH for logging/child procs
    path = [
      pkgs.coreutils pkgs.util-linux pkgs.openssh pkgs.rsync
      pkgs.postgresql_15 pkgs.gnutar pkgs.zstd pkgs.jq pkgs.bash
      pkgs.docker pkgs.curl pkgs.inetutils pkgs.systemd
    ];
  };

  # Convenience: restore the most recent snapshot by starting the instance
  systemd.services.netbox-restore-latest = {
    description = "Restore NetBox from the latest snapshot on storage-01";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" "netbox-backup-keygen.service" "netbox-backup-knownhosts.service" ];
    serviceConfig = { Type = "oneshot"; };
    path = [ pkgs.coreutils pkgs.openssh pkgs.gnugrep pkgs.bash pkgs.inetutils pkgs.systemd ];
    script = ''
      set -euo pipefail
      HOST="$(${pkgs.inetutils}/bin/hostname)"
      SSH="${pkgs.openssh}/bin/ssh -i /var/lib/netbox-backup/id_ed25519 \
           -o IdentitiesOnly=yes \
           -o UserKnownHostsFile=/var/lib/netbox-backup/known_hosts \
           -o StrictHostKeyChecking=yes"

      TS="$($SSH backup@storage-01 "ls -1 /var/storage/backups/netbox/$HOST/" \
           | ${pkgs.gnugrep}/bin/grep -E '^[0-9]{8}T[0-9]{6}Z$' \
           | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/tail -n1)"

      test -n "$TS" || { echo "No snapshots found for host $HOST"; exit 1; }
      echo "→ Latest snapshot: $TS"

      # Start the instance unit with the timestamp
      ${pkgs.systemd}/bin/systemctl start "netbox-restore@$TS"
    '';
  };

  # Nginx reverse proxy for Netbox
  services.nginx.virtualHosts."_" = {
    # Catch every Host header, including raw IPs
    default = true;
    serverAliases = [ "netbox.local" "10.1.10.55" "localhost" ];

    # Be explicit about being the default on IPv4 & IPv6
    listen = [
      { addr = "0.0.0.0"; port = 80; }
      { addr = "[::]";   port = 80; }
    ];

    # Security headers (keep CORS at the app layer)
    extraConfig = ''
      add_header X-Frame-Options DENY;
      add_header X-Content-Type-Options nosniff;
      add_header X-XSS-Protection "1; mode=block";
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
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
