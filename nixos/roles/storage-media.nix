{ config, pkgs, lib, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
    ../profiles/sops.nix
    ../profiles/nvim-tiny-plugins.nix
    ../profiles/observability/client.nix
  ];

  system.stateVersion = "24.11";

  # Stable writer identity so MediaMTX can write with root_squash still on.
  users.groups.media = { gid = 988; };
  users.users.media  = {
    isSystemUser = true;
    uid = 988;
    group = "media";
    home = "/srv/media";
  };

  # Media tree (directories are group-sticky for team workflows)
  systemd.tmpfiles.rules = [
    "d /srv/media 2775 media media -"
    "d /srv/media/movies 2775 media media -"
    "d /srv/media/tv 2775 media media -"
    "d /srv/media/music 2775 media media -"
    "d /srv/media/streams 2775 media media -"
    "d /srv/media/recordings 2775 media media -"
  ];

  # NFSv4 export; root_squash keeps client root from being root on server.
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /srv/media 10.0.0.0/24(rw,sync,no_subtree_check,root_squash)
    /srv/media 10.0.2.0/24(rw,sync,no_subtree_check,root_squash)
  '';
  networking.firewall.allowedTCPPorts = lib.mkAfter [ 2049 80 443 ];
  networking.firewall.allowedUDPPorts = lib.mkAfter [ 2049 ];

  # Optional SMB for human ingest (kept tight to the media user)
  services.samba = {
    enable = true;
    openFirewall = true;
    shares.media = {
      path = "/srv/media";
      "read only" = "no";
      "guest ok" = "no";
      "browseable" = "yes";
      "valid users" = "media";
      "force user" = "media";
      "force group" = "media";
      "create mask" = "0664";
      "directory mask" = "2775";
    };
  };

  environment.systemPackages = with pkgs; [ nfs-utils rsync ];
}
