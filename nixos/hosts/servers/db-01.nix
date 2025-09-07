{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../roles/db-server.nix ];

  # Host-specific configuration
  networking.hostName = "db-01";
  networking.domain = "example.com";

  # Root filesystem definition
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Network configuration
  networking.interfaces.eth0 = {
    useDHCP = true;
  };

  # Database-specific configuration
  services.postgresql = {
    settings = {
      # Connection settings
      max_connections = 200;
      shared_buffers = "512MB";
      effective_cache_size = "2GB";
      
      # Write-ahead logging
      wal_level = "replica";
      max_wal_senders = 3;
      wal_keep_segments = 8;
      
      # Replication
      hot_standby = true;
      max_standby_archive_delay = "30s";
      max_standby_streaming_delay = "30s";
    };
  };

  # Create application databases
  services.postgresql.ensureDatabases = [ 
    "myapp_production"
    "myapp_staging" 
    "myapp_development"
  ];
  
  services.postgresql.ensureUsers = [
    {
      name = "myapp";
      ensurePermissions = {
        "DATABASE myapp_production" = "ALL PRIVILEGES";
        "DATABASE myapp_staging" = "ALL PRIVILEGES";
        "DATABASE myapp_development" = "ALL PRIVILEGES";
      };
    }
    {
      name = "backup";
      ensurePermissions = {
        "DATABASE myapp_production" = "CONNECT";
        "DATABASE myapp_staging" = "CONNECT";
        "DATABASE myapp_development" = "CONNECT";
      };
    }
  ];

  # Backup configuration
  services.borgbackup.repos."db-backup" = {
    path = "/backup/db";
    authorizedKeys = [
      # Add your backup SSH key here
      "ssh-rsa AAAA..."
    ];
  };

  # System packages for database management
  environment.systemPackages = with pkgs; [
    # Database tools
    postgresql_15
    pgcli
    pg_top
    pg_repack
    
    # Monitoring
    htop
    iotop
    smartmontools
    
    # Backup tools
    borgbackup
    restic
  ];

  # Database monitoring (simplified)
  # Note: Prometheus exporter configuration should be done via config file
  # This enables the service but doesn't configure specific data sources
}

