# SOPS secrets management profile
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/prod.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
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
      
      keycloak-admin-password = {
        owner = "keycloak";
        group = "keycloak";
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
    };
  };

  # Ensure sops-nix key directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root"
  ];
}
