{ config, lib, pkgs, cfg, ... }:
let
  role = cfg.role or null;
  tag =
    if role == "k3s" then "tag:k3s"
    else if lib.elem role [ "jellyfin-lite" "mediamtx-lite" ] then "tag:media"
    else if lib.elem role [ "storage-media" "storage-backup" "storage-server" ] then "tag:storage"
    else if role == "pxe-lite" then "tag:pxe"
    else "tag:infra";

  haveTsKey =
    lib.hasAttrByPath [ "sops" "secrets" "tailscale-authkey" ] config;
in
{
  options.nbg.tailscale.advertisedTag = lib.mkOption {
    type = lib.types.str;
    default = tag;
    description = "Tailscale tag to advertise; defaults from cfg.role.";
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;  # opens UDP 41641 etc.
    # Headless join if you add the secret (optional on day 1):
    authKeyFile = lib.mkIf haveTsKey config.sops.secrets."tailscale-authkey".path;
    extraUpFlags = [
      "--hostname=${config.networking.hostName}"
      "--advertise-tags=${config.nbg.tailscale.advertisedTag}"
      # Not enabling --ssh in Sprint 1; we stick to OpenSSH.
    ];
  };

  # Allow SSH only on the Tailscale interface.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  networking.firewall.checkReversePath = "loose"; # common with TS to avoid rpfilter issues
}
