# Application template service module
{ config, pkgs, lib, ... }:

{
  # Frontend application container
  virtualisation.oci-containers.containers.frontend = {
    image = "nginx:alpine";
    ports = [ "3000:80" ];
    
    volumes = [
      "/var/lib/applications/frontend:/usr/share/nginx/html:ro"
    ];
    
    environment = {
      TZ = "UTC";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
    ];
  };

  # API application container
  virtualisation.oci-containers.containers.api = {
    image = "node:18-alpine";
    ports = [ "8000:3000" ];
    
    volumes = [
      "/var/lib/applications/api:/app:ro"
    ];
    
    environment = {
      TZ = "UTC";
      NODE_ENV = "production";
      DATABASE_URL = "postgresql://myapp:password@localhost:5432/myapp";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
    ];
  };

  # Create application directories
  systemd.tmpfiles.rules = [
    "d /var/lib/applications 0755 root root"
    "d /var/lib/applications/frontend 0755 root root"
    "d /var/lib/applications/api 0755 root root"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    nodejs
    npm
  ];
}
