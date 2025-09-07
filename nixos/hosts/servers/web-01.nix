{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../roles/server.nix ];

  # Host-specific configuration
  networking.hostName = "web-01";
  networking.domain = "example.com";

  # Root filesystem definition
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Network configuration
  networking.interfaces.eth0 = {
    useDHCP = true;
  };

  # Nginx virtual hosts for this server
  services.nginx.virtualHosts = {
    "api.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
    
    "app.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # Cloudflare tunnel configuration (simplified)
  # Note: Tunnel configuration should be done via cloudflared config file
  # This enables the service but doesn't configure specific tunnels

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    # Web development tools
    nodejs_20
    yarn
    python3
    pipenv
    
    # Monitoring tools
    htop
    iotop
    nethogs
  ];
}

