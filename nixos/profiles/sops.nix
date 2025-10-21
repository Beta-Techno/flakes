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

      # ── Grafana ─────────────────────────────────────────────────
      grafana-admin-password = lib.mkIf config.services.grafana.enable {
        # Write exactly where Grafana profile reads from
        path  = "/var/lib/grafana/admin-password";
        owner = "grafana"; group = "grafana"; mode = "0400";
        restartUnits = [ "grafana.service" ];
      };
      grafana-secret-key = lib.mkIf config.services.grafana.enable {
        path  = "/var/lib/grafana/secret-key";
        owner = "grafana"; group = "grafana"; mode = "0400";
        restartUnits = [ "grafana.service" ];
      };
      "gcp-bq-sa.json" = lib.mkIf config.services.grafana.enable {
        path  = "/var/lib/grafana/gcp-bq-sa.json";
        owner = "grafana"; group = "grafana"; mode = "0400";
        restartUnits = [ "grafana.service" ];
      };
      "gcp-bq-sa.pem" = lib.mkIf config.services.grafana.enable {
        path  = "/var/lib/grafana/gcp-bq-sa.pem";
        owner = "grafana"; group = "grafana"; mode = "0400";
        restartUnits = [ "grafana.service" ];
      };

      # ── K3s ──────────────────────────────────────────────────────
      k3s-token = lib.mkIf config.services.k3s.enable {
        path = "/run/secrets/k3s-token";
        owner = "root";
        group = "root";
        mode  = "0400";
      };

      # ── Tailscale ────────────────────────────────────────────────
      tailscale-authkey = lib.mkIf config.services.tailscale.enable {
        path = "/run/secrets/tailscale-authkey";
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
