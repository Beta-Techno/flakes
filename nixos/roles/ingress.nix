# Ingress role - Single front door for all HTTP(S) traffic
# This VM acts as the canonical edge of the network, handling both:
# 1. Public traffic via Cloudflare Tunnel (no open ports to internet)
# 2. Internal LAN traffic via nginx reverse proxy
{ config, lib, pkgs, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
    ../profiles/cloudflared-system.nix
    ../profiles/sops.nix
    ../profiles/nvim-tiny-plugins.nix
    ../profiles/observability/client.nix
  ];

  # ============================================================================
  # NGINX REVERSE PROXY CONFIGURATION
  # ============================================================================

  services.nginx = {
    # Nginx already enabled in profiles/nginx.nix

    virtualHosts = {
      # Default catch-all: deny unknown hosts (security best practice)
      "_" = {
        default = true;
        extraConfig = ''
          return 444;  # Close connection without response
        '';
      };

      # ──────────────────────────────────────────────────────────────────────
      # INFRASTRUCTURE SERVICES (NixOS-managed)
      # ──────────────────────────────────────────────────────────────────────

      # Netbox - IPAM/DCIM (Network documentation and inventory)
      "netbox.betatechnology.org" = {
        locations."/" = {
          proxyPass = "http://netbox-01:80";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      # Also serve Netbox on .local for LAN access
      "netbox.local" = {
        locations."/" = {
          proxyPass = "http://netbox-01:80";
          proxyWebsockets = true;
        };
      };

      # Observability - Prometheus/Loki/Grafana stack
      "obs.betatechnology.org" = {
        locations."/" = {
          proxyPass = "http://observability-01:80";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "observability.local" = {
        locations."/" = {
          proxyPass = "http://observability-01:80";
          proxyWebsockets = true;
        };
      };

      # ──────────────────────────────────────────────────────────────────────
      # MEDIA SERVICES
      # ──────────────────────────────────────────────────────────────────────

      # Jellyfin - Media server (movies/TV)
      "media.betatechnology.org" = {
        locations."/" = {
          proxyPass = "http://jellyfin-01:8096";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Jellyfin-specific headers
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $http_connection;

            # Disable buffering for large media files
            proxy_buffering off;
          '';
        };
      };

      "media.local" = {
        locations."/" = {
          proxyPass = "http://jellyfin-01:8096";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
          '';
        };
      };

      # MediaMTX - Streaming server (RTSP/RTMP/HLS)
      "stream.betatechnology.org" = {
        locations."/" = {
          proxyPass = "http://mediamtx-01:8888";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Disable buffering for live streams
            proxy_buffering off;
          '';
        };
      };

      "stream.local" = {
        locations."/" = {
          proxyPass = "http://mediamtx-01:8888";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
          '';
        };
      };

      # ──────────────────────────────────────────────────────────────────────
      # INFRASTRUCTURE UTILITIES
      # ──────────────────────────────────────────────────────────────────────

      # PXE Boot server (iPXE scripts and boot files)
      "pxe.betatechnology.org" = {
        locations."/" = {
          proxyPass = "http://pxe-01:80";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "pxe.local" = {
        locations."/" = {
          proxyPass = "http://pxe-01:80";
        };
      };

      # ──────────────────────────────────────────────────────────────────────
      # KUBERNETES WILDCARD (proxy to Traefik ingress controller)
      # ──────────────────────────────────────────────────────────────────────

      # Wildcard: *.k8s.betatechnology.org → Traefik on k3s-01
      # This allows K8s IngressRoutes to handle their own routing
      "~^(?<subdomain>.+)\\.k8s\\.betatechnology\\.org$" = {
        locations."/" = {
          proxyPass = "http://k3s-01:80";
          proxyWebsockets = true;
          extraConfig = ''
            # Pass the original Host header to Traefik
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      # ──────────────────────────────────────────────────────────────────────
      # MONITORING & STATUS
      # ──────────────────────────────────────────────────────────────────────

      # Nginx status endpoint (metrics for prometheus nginx_exporter)
      "localhost" = {
        locations."/nginx_status" = {
          extraConfig = ''
            stub_status;
            allow 127.0.0.1;
            deny all;
          '';
        };
      };
    };
  };

  # ============================================================================
  # CLOUDFLARE TUNNEL CONFIGURATION
  # ============================================================================

  services.cloudflared.tunnels."beta-ingress" = {
    # Credentials file managed by SOPS (encrypted in secrets/prod.yaml)
    credentialsFile = config.sops.secrets."cloudflared-beta-creds".path;

    # Ingress rules: map public hostnames to localhost (nginx handles routing)
    ingressRules = [
      # Infrastructure services
      {
        hostname = "netbox.betatechnology.org";
        service = "http://localhost";
      }
      {
        hostname = "obs.betatechnology.org";
        service = "http://localhost";
      }

      # Media services
      {
        hostname = "media.betatechnology.org";
        service = "http://localhost";
      }
      {
        hostname = "stream.betatechnology.org";
        service = "http://localhost";
      }

      # Infrastructure utilities
      {
        hostname = "pxe.betatechnology.org";
        service = "http://localhost";
      }

      # Kubernetes wildcard (*.k8s.betatechnology.org)
      {
        hostname = "*.k8s.betatechnology.org";
        service = "http://localhost";
      }

      # Catch-all: deny everything else
      {
        service = "http_status:404";
      }
    ];
  };

  # ============================================================================
  # SOPS SECRETS
  # ============================================================================

  # Cloudflare tunnel credentials (created in Cloudflare Zero Trust UI)
  sops.secrets."cloudflared-beta-creds" = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
    # Actual secret is in secrets/prod.yaml (encrypted)
  };

  # ============================================================================
  # FIREWALL CONFIGURATION
  # ============================================================================

  networking.firewall = {
    # Allow HTTP/HTTPS on LAN interface (for internal clients)
    # Cloudflare tunnel is outbound-only, so no public ports needed
    allowedTCPPorts = [ 80 443 ];

    # Note: SSH and Prometheus exporter (9100) are only allowed on tailscale0
    # (configured in base.nix and observability/client.nix)
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # HTTP debugging
    curl
    wget
    jq

    # Network tools
    dnsutils  # dig, nslookup
    netcat
    tcpdump

    # Monitoring
    htop
    iotop
  ];
}
