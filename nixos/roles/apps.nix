# Applications role - bundles application services
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/postgres.nix
    ../profiles/prom.nix
    ../services/applications/template/default.nix
  ];

  # Application-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    5432  # PostgreSQL
    3000  # Frontend apps
    8000  # API apps
  ];

  # Application storage
  fileSystems."/var/lib/applications" = {
    device = "/dev/disk/by-label/applications";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # System packages for application development
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    nodejs
    python3
    go
    rustc
    
    # Database tools
    postgresql_15
    pgcli
    
    # Monitoring tools
    htop
    iotop
    
    # Network tools
    nmap
    tcpdump
  ];
}
