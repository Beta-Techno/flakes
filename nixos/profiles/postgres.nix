{ config, pkgs, lib, ... }:

{
  # Enable PostgreSQL
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15; # Specify version
    
    # Database configuration
    settings = {
      # Memory settings
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = "0.9";
      wal_buffers = "16MB";
      default_statistics_target = "100";
      
      # Logging
      log_min_duration_statement = "1000";
      log_checkpoints = true;
      log_connections = true;
      log_disconnections = true;
      log_lock_waits = true;
      
      # Security
      ssl = true;
      ssl_cert_file = "/var/lib/postgresql/server.crt";
      ssl_key_file = "/var/lib/postgresql/server.key";
    };

    # Authentication configuration
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            md5
      host    all             all             ::1/128                 md5
    '';
  };

  # Create database user
  services.postgresql.ensureDatabases = [ "myapp" ];
  services.postgresql.ensureUsers = [
    {
      name = "myapp";
      ensurePermissions = {
        "DATABASE myapp" = "ALL PRIVILEGES";
      };
    }
  ];

  # System packages for database management
  environment.systemPackages = with pkgs; [
    postgresql_15
    pgcli
  ];

  # Open firewall port for PostgreSQL (if needed)
  # networking.firewall.allowedTCPPorts = [ 5432 ];
}

