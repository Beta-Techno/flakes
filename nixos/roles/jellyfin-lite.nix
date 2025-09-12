{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix            # keep; useful if/when you add a vhost
    ../services/media/jellyfin/default.nix
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
  ];

  # Open the web UI and optional reverse-proxy ports.
  networking.firewall.allowedTCPPorts = [ 22 8096 80 443 ];

  # OPTIONAL: enable hw transcode (safe even if /dev/dri isn't present)
  hardware.graphics.enable = true;
  virtualisation.oci-containers.containers.jellyfin.extraOptions =
    lib.mkAfter [
      "--device=/dev/dri:/dev/dri"   # Intel/AMD VAAPI
      # If this box has NVIDIA + nvidia-container-toolkit, also add:
      # "--gpus=all"
    ];
}
