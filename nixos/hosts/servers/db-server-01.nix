# Database server host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration
  networking.interfaces.ens18.ipv4.addresses = [
    { address = "10.0.0.13"; prefixLength = 24; }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  # Disk layout (if using disko)
  disko.devices = (import ../../disko/db-server-01.nix { inherit lib; }).disko.devices;

  # Database-specific overrides
  services.postgresql.settings = {
    # Performance tuning for database server
    shared_buffers = "512MB";
    effective_cache_size = "2GB";
    maintenance_work_mem = "128MB";
    checkpoint_completion_target = "0.9";
    wal_buffers = "32MB";
    default_statistics_target = "100";
  };

  # Database-specific system packages
  environment.systemPackages = with pkgs; [
    # Database-specific tools
    postgresql_15
    pgcli
    pg_top
    postgresqlPackages.pg_repack
    postgresqlPackages.pg_stat_statements
  ];
}
