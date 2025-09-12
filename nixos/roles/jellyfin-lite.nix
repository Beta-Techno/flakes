{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix            # keep; useful if/when you add a vhost
  ];

  system.stateVersion = "24.11";

  # The Jellyfin service module uses jellyfin:jellyfin in tmpfiles → provide it.
  users.groups.jellyfin = { };
  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    home  = "/var/lib/jellyfin";
  };

  # Make a local media folder now; replace with an NFS/SMB mount later.
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 root root -"
    "d /var/lib/jellyfin 0755 jellyfin jellyfin"
    "d /var/lib/jellyfin/config 0755 jellyfin jellyfin"
    "d /var/lib/jellyfin/cache 0755 jellyfin jellyfin"
  ];

  # Open the web UI and optional reverse-proxy ports.
  networking.firewall.allowedTCPPorts = [ 22 8096 80 443 ];

  # OPTIONAL: enable hw transcode (safe even if /dev/dri isn't present)
  hardware.graphics.enable = true;

  # Jellyfin OCI container (defined directly in role like Netbox)
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:latest";
    # Using host networking; container binds directly to host ports
    
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
      "--device=/dev/dri:/dev/dri"   # Intel/AMD VAAPI
      # If this box has NVIDIA + nvidia-container-toolkit, also add:
      # "--gpus=all"
    ];
  };

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
