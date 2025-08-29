{ config, pkgs, lib, ... }:

{
  imports = [
    ../roles/server.nix
    ../profiles/postgres.nix
  ];

  # Database server specific settings
  system.stateVersion = "23.11";

  # Optimize for database workloads
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = 1;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    
    # Network tuning
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  # Database-specific firewall rules
  networking.firewall.allowedTCPPorts = [ 22 80 443 5432 ];

  # Backup configuration for databases
  services.borgbackup.repos = {
    # Example database backup
    # "db-backup" = {
    #   path = "/backup/db";
    #   authorizedKeys = [ "ssh-rsa AAAA..." ];
    # };
  };

  # Database monitoring
  services.postgresql.settings = {
    # Enable query logging for monitoring
    log_statement = "all";
    log_min_duration_statement = 1000;
    
    # Performance tuning
    shared_buffers = "256MB";
    effective_cache_size = "1GB";
    maintenance_work_mem = "64MB";
    checkpoint_completion_target = "0.9";
    wal_buffers = "16MB";
    default_statistics_target = "100";
  };
}

