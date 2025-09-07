# Keycloak service module
{ config, pkgs, lib, ... }:

{
  # Keycloak OCI container
  virtualisation.oci-containers.containers.keycloak = {
    image = "quay.io/keycloak/keycloak:25.0.0";
    ports = [ "8081:8080" ];
    
    volumes = [
      "/var/lib/keycloak/data:/opt/keycloak/data:rw"
    ];
    
    environment = {
      TZ = "UTC";
      KEYCLOAK_ADMIN = "admin";
      KEYCLOAK_ADMIN_PASSWORD = "$__file{/var/lib/keycloak/admin-password}";
      KC_DB = "postgres";
      KC_DB_URL = "jdbc:postgresql://localhost:5432/keycloak";
      KC_DB_USERNAME = "keycloak";
      KC_DB_PASSWORD = "$__file{/var/lib/keycloak/db-password}";
      KC_HOSTNAME = "auth.local";
      KC_HOSTNAME_PORT = "8081";
      KC_HOSTNAME_STRICT = "false";
      KC_HOSTNAME_STRICT_HTTPS = "false";
      KC_HTTP_ENABLED = "true";
      KC_PROXY = "edge";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
    ];
  };

  # Create Keycloak directories
  systemd.tmpfiles.rules = [
    "d /var/lib/keycloak 0755 keycloak keycloak"
    "d /var/lib/keycloak/data 0755 keycloak keycloak"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    keycloak
  ];
}
