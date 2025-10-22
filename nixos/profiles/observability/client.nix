# Observability client profile - runs on every host
# Exports metrics via node_exporter and ships logs via promtail
{ config, lib, pkgs, ... }:

let
  # Where promtail ships logs; use Tailscale DNS here if you prefer
  lokiPush = "http://observability-01:3100/loki/api/v1/push";
in
{
  # Metrics
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";  # reachable from tailnet
    port = 9100;
  };

  # Open exporter ports only on Tailscale, not the world
  networking.firewall.interfaces.tailscale0.allowedTCPPorts =
    (config.networking.firewall.interfaces.tailscale0.allowedTCPPorts or []) ++ [ 9100 ];

  # Logs
  services.promtail = {
    enable = true;
    configuration = {
      server = { http_listen_port = 9080; grpc_listen_port = 0; };
      positions.filename = "/var/lib/promtail/positions.yaml";
      clients = [{ url = lokiPush; }];
      scrape_configs = [
        {
          job_name = "journal";
          journal.max_age = "12h";
          journal.labels = { job = "systemd-journal"; host = config.networking.hostName; };
          relabel_configs = [{ source_labels = ["__journal__systemd_unit"]; target_label = "unit"; }];
        }
        {
          job_name = "nginx";
          static_configs = [{
            targets = [ "localhost" ];
            labels = { job = "nginx"; __path__ = "/var/log/nginx/*.log"; host = config.networking.hostName; };
          }];
        }
        # Docker logs (if the host has Docker)
        (lib.mkIf config.virtualisation.docker.enable {
          job_name = "docker";
          static_configs = [{
            targets = [ "localhost" ];
            labels = { job = "docker"; __path__ = "/var/lib/docker/containers/*/*-json.log"; host = config.networking.hostName; };
          }];
        })
      ];
    };
  };
}
