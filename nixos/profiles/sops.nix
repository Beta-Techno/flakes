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
    
    # Secrets that will be available to the system
    secrets = {
      # Database passwords
      postgres-password = {
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };
      
      # API keys
      netbox-api-key = {
        owner = "netbox";
        group = "netbox";
        mode = "0400";
      };
      
      # NetBox admin password (for deterministic first boot)
      netbox-admin-password = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
      
      # Make this safe on hosts that don't run Keycloak; real Keycloak hosts
      # can override owner/group to "keycloak" in their module.
      keycloak-admin-password = {
        owner = lib.mkDefault "root";
        group = lib.mkDefault "root";
        mode = "0400";
      };
      
      # SSL certificates
      ssl-cert = {
        owner = "nginx";
        group = "nginx";
        mode = "0444";
      };
      
      ssl-key = {
        owner = "nginx";
        group = "nginx";
        mode = "0400";
      };
      
      # NetBox backup SSH private key
      netbox-backup-private-key = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };

  # Ensure sops-nix key directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root"
  ];
}
