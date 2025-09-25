# SOPS secrets management profile
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/prod.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    
    # Secrets, gated so they only exist where the owner exists
    secrets = {
      # Only if Postgres is actually enabled on the host
      postgres-password = lib.mkIf config.services.postgresql.enable {
        owner = "postgres";
        group = "postgres";
        mode  = "0400";
      };

      # Only on hosts that define the 'netbox' system user
      netbox-api-key = lib.mkIf (config.users.users ? netbox) {
        owner = "netbox";
        group = "netbox";
        mode  = "0400";
      };
      netbox-admin-password = lib.mkIf (config.users.users ? netbox) {
        owner = "root";
        group = "root";
        mode  = "0400";
      };

      # Safe default; override in a Keycloak role when you add one
      keycloak-admin-password = {
        owner = lib.mkDefault "root";
        group = lib.mkDefault "root";
        mode  = "0400";
      };

      # Only when nginx is enabled on the host
      ssl-cert = lib.mkIf config.services.nginx.enable {
        owner = "nginx";
        group = "nginx";
        mode  = "0444";
      };
      ssl-key = lib.mkIf config.services.nginx.enable {
        owner = "nginx";
        group = "nginx";
        mode  = "0400";
      };

      # Private key only on the NetBox host (push backups out)
      netbox-backup-private-key = lib.mkIf (config.users.users ? netbox) {
        owner = "root";
        group = "root";
        mode  = "0600";
      };
      # Public key is needed on storage to authorize NetBox
      netbox-backup-public-key = {
        owner = "root";
        group = "root";
        mode  = "0400";
      };
    };
  };

  # Ensure sops-nix key directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root"
  ];
}
