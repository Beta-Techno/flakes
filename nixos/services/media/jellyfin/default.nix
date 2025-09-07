# Jellyfin service module
{ config, pkgs, lib, ... }:

{
  # Jellyfin OCI container
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:latest";
    ports = [ "8096:8096" ];
    
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
      "--restart=unless-stopped"
      "--network=host"
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
}
