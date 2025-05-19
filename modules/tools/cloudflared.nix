{ config, pkgs, lib, ... }:

{
  # ── Cloudflared package ───────────────────────────────────────
  home.packages = with pkgs; [
    cloudflared
  ];

  # ── Cloudflared systemd service ───────────────────────────────
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  # ── Cloudflared configuration directory ───────────────────────
  home.file.".cloudflared".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/cloudflared";
} 