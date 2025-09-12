# DEPRECATED: Do not use; Jellyfin and MediaMTX are now split into -lite roles.
# Media role - bundles media services
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/prom.nix
    ../services/media/jellyfin/default.nix
    ../services/media/mediamtx/default.nix
  ];

  # Media-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    8096  # Jellyfin
    8554  # MediaMTX RTSP
    1935  # MediaMTX RTMP
  ];

  # Shared media storage
  fileSystems."/mnt/media" = {
    device = "10.0.0.20:/srv/media";  # Your NAS/NFS
    fsType = "nfs";
    options = [ "noatime" "nfsvers=4.2" ];
  };

  # Local media cache
  fileSystems."/var/lib/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # System packages for media management
  environment.systemPackages = with pkgs; [
    # Media tools
    jellyfin
    ffmpeg
    mediainfo
    
    # Monitoring tools
    htop
    iotop
    
    # Network tools
    nmap
    tcpdump
  ];
}
