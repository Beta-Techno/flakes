{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../roles/server.nix ];

  # Host-specific configuration
  networking.hostName = "web-01";
  networking.domain = "example.com";

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

  # Cloudflare tunnel configuration
  services.cloudflared.tunnels."web-tunnel" = {
    credentialsFile = "/etc/cloudflared/web-tunnel.json";
    ingressRules = [
      {
        hostname = "api.example.com";
        service = "http://localhost:8080";
      }
      {
        hostname = "app.example.com";
        service = "http://localhost:3000";
      }
      {
        service = "http_status:404";
      }
    ];
  };

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

