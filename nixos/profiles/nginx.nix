{ config, pkgs, lib, ... }:

{
  # Enable nginx
  services.nginx = {
    enable = true;
    
    # Recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Virtual hosts configuration
    virtualHosts = {
      # Example virtual host
      # "example.com" = {
      #   enableACME = true;
      #   forceSSL = true;
      #   locations."/" = {
      #     proxyPass = "http://127.0.0.1:8080";
      #     proxyWebsockets = true;
      #   };
      # };
    };

    # Global configuration
    appendHttpConfig = ''
      # Rate limiting zone (use per‑vhost with: limit_req zone=api burst=20 nodelay;)
      limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    '';
  };

  # Open firewall ports for nginx
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Enable ACME for Let's Encrypt certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com"; # Change this
  };
}

