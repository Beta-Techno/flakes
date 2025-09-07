# Applications role - bundles application services
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/postgres.nix
    ../profiles/prom.nix
  ];

  # Application-specific configuration
  networking.firewall.allowedTCPPorts = [
    80    # HTTP
    443   # HTTPS
    5432  # PostgreSQL
    3000  # Frontend apps
    8000  # API apps
  ];

  # Enable Docker for your containerized applications
  virtualisation.docker.enable = true;
  users.users.root.extraGroups = [ "docker" ];

  # Example: Simple web application container
  # Replace this with your actual GitHub repo container
  virtualisation.oci-containers.containers.myapp = {
    image = "nginx:alpine";
    ports = [ "3000:80" ];
    
    volumes = [
      "/var/lib/applications/html:/usr/share/nginx/html:ro"
    ];
    
    environment = {
      TZ = "UTC";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
    ];
  };

  # Create application directories and welcome page
  systemd.tmpfiles.rules = [
    "d /var/lib/applications 0755 root root"
    "d /var/lib/applications/html 0755 root root"
    "f /var/lib/applications/html/index.html 0644 root root - <!DOCTYPE html>
<html>
<head>
    <title>My Application</title>
</head>
<body>
    <h1>Welcome to My Application</h1>
    <p>This is a placeholder for your GitHub repo container.</p>
    <p>Replace the myapp container with your actual application.</p>
</body>
</html>"
  ];

  # System packages for application development
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    nodejs
    python3
    go
    
    # Database tools
    postgresql_15
    pgcli
    
    # Monitoring tools
    htop
    iotop
    
    # Docker tools
    docker-compose
  ];
}
