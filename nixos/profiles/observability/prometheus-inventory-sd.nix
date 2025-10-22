# Inventory-driven service discovery for Prometheus
# Generates scrape targets from inventories/prod.nix
{ lib, ... }:

let
  inventory = import ../../inventories/prod.nix;
  hosts = builtins.attrNames inventory;

  mkNode = host: {
    targets = [ "${host}:9100" ];
    labels  = { instance = host; role = (inventory.${host}.role or "unknown"); env = "prod"; };
  };

  nodes = builtins.map mkNode hosts;
in
{
  environment.etc."prometheus/file_sd/nodes.json".text = builtins.toJSON nodes;

  services.prometheus.scrapeConfigs = lib.mkAfter [
    {
      job_name = "node";
      file_sd_configs = [{
        files = [ "/etc/prometheus/file_sd/nodes.json" ];
        refresh_interval = "1m";
      }];
      relabel_configs = [
        { source_labels = [ "__address__" ]; regex = "(.+):(.*)"; target_label = "instance"; replacement = "$1"; }
      ];
    }
  ];
}
