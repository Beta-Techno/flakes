# Jellyfin service module
{ config, pkgs, lib, ... }:

{
  # Jellyfin OCI container
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:latest";
    # Using host networking; container binds directly to host ports
    # (so no need for explicit port mappings)
    
    volumes = [
      "/var/lib/jellyfin/config:/config:rw"
      "/var/lib/jellyfin/cache:/cache:rw"
      "/mnt/media:/media:ro"
    ];
    
    environment = {
      TZ = "UTC";
      JELLYFIN_PublishedServerUrl = "https://media.local";
    };
    
    extraOptions = [
      "--network=host"
      # Let systemd handle restarts instead of Docker
    ];
  };

  # Create Jellyfin directories
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0755 jellyfin jellyfin"
    "d /var/lib/jellyfin/config 0755 jellyfin jellyfin"
    "d /var/lib/jellyfin/cache 0755 jellyfin jellyfin"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    jellyfin
  ];

  # Ensure Jellyfin starts properly and restarts on failure
  systemd.services.docker-jellyfin = {
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
}
