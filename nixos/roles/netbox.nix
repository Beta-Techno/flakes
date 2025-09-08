# Netbox role - dedicated IPAM/DCIM server
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/postgres.nix
  ];

  # Bootloader: Proxmox handles boot directly from disk (like nick-vm)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;  # Disable grub as well
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.efi.efiSysMountPoint = lib.mkForce null;  # Don't try to mount /boot 
  
  # Disable bootloader requirement for VM environment
  # Proxmox handles boot directly from disk
  boot.loader.grub.devices = lib.mkForce [ ];  # Empty list disables grub requirement

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

  # Netbox container
  virtualisation.oci-containers.containers.netbox = {
    image = "netboxcommunity/netbox:v4.0.0";
    ports = [ "8080:8080" ];
    
    environment = {
      TZ = "UTC";
      DB_HOST = "localhost";
      DB_PORT = "5432";
      DB_NAME = "netbox";
      DB_USER = "netbox";
      DB_PASSWORD = "netbox123";  # Simple password for now
      REDIS_HOST = "localhost";
      REDIS_PORT = "6379";
      SECRET_KEY = "netbox-secret-key-change-me";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
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
