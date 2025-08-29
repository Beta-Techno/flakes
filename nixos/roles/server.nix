{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
    ../profiles/nginx.nix
    ../profiles/cloudflared-system.nix
  ];

  # Server-specific settings
  system.stateVersion = "23.11";

  # Enable automatic security updates
  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-23.11";
  };

  # Backup configuration
  services.borgbackup.repos = {
    # Example backup configuration
    # "backup" = {
    #   path = "/backup";
    #   authorizedKeys = [ "ssh-rsa AAAA..." ];
    # };
  };

  # Monitoring and logging
  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev" "netstat" "textfile" "time" "vmstat" "logind" "interrupts" "tcpstat" ];
      };
    };
  };

  # System monitoring
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        domain = "localhost";
      };
    };
  };
}

