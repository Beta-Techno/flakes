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

  # Database-specific configuration is handled by the db-server role
  # Additional PostgreSQL settings can be added here if needed

  # PostgreSQL configuration is handled by the postgres profile
  # Additional databases can be added here if needed

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

