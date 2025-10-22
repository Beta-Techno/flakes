{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../services/media/mediamtx/default.nix
    ../profiles/sops.nix
    ../profiles/nvim-tiny-plugins.nix
    ../profiles/observability/client.nix
  ];

  system.stateVersion = "24.11";

  # Open service ports (HTTP added for HLS/API/metrics; RTSP/RTMP aren't HTTP)
  networking.firewall.allowedTCPPorts = [ 80 443 8554 1935 8888 8889 9997 9998 ];

  # Optional: serve only the HTTP endpoints via nginx (HLS / API / metrics).
  services.nginx.virtualHosts."stream.local" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:8888"; # HLS player
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:9997/";
      proxyWebsockets = true;
    };
    locations."/metrics" = {
      proxyPass = "http://127.0.0.1:9998/metrics";
    };
  };

  # Keep the container always up
  systemd.services.docker-mediamtx.serviceConfig = {
    Restart = "always";
    RestartSec = 5;
  };
}
