{ config, pkgs, lib, ... }:

{
  # Enable cloudflared system service
  services.cloudflared = {
    enable = true;
    
    # Tunnel configuration
    tunnels = {
      # Example tunnel configuration
      # "my-tunnel" = {
      #   credentialsFile = "/etc/cloudflared/my-tunnel.json";
      #   ingressRules = [
      #     {
      #       hostname = "api.example.com";
      #       service = "http://localhost:8080";
      #     }
      #     {
      #       hostname = "app.example.com";
      #       service = "http://localhost:3000";
      #     }
      #     {
      #       service = "http_status:404";
      #     }
      #   ];
      # };
    };
  };

  # Create cloudflared user
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};

  # Systemd service configuration
  systemd.services.cloudflared = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}

