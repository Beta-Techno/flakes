# Loki logging profile
{ config, pkgs, lib, ... }:

{
  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        grpc_listen_port = 9096;
      };
      
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      
      schema_config = {
        configs = [{
          from = "2020-10-24";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };
      
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        max_cache_freshness_per_query = "10m";
        split_queries_by_interval = "15m";
        max_query_parallelism = 32;
        max_query_series = 100000;
        max_query_lookback = "1h";
        max_entries_limit_per_query = 5000;
        max_query_length = "721h";
        cardinality_limit = 100000;
        max_streams_per_user = 10000;
        max_line_size = 256000;
      };
      
      chunk_store_config = {
        max_look_back_period = "0s";
      };
      
      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
      };
    };
  };

  # Promtail for log collection
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      
      positions = {
        filename = "/tmp/positions.yaml";
      };
      
      clients = [{
        url = "http://127.0.0.1:3100/loki/api/v1/push";
      }];
      
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "localhost";
            };
          };
          relabel_configs = [{
            source_labels = ["__journal__systemd_unit"];
            target_label = "unit";
          }];
        }
        {
          job_name = "nginx";
          static_configs = [{
            targets = ["localhost"];
            labels = {
              job = "nginx";
              __path__ = "/var/log/nginx/*.log";
            };
          }];
        }
        {
          job_name = "postgresql";
          static_configs = [{
            targets = ["localhost"];
            labels = {
              job = "postgresql";
              __path__ = "/var/log/postgresql/*.log";
            };
          }];
        }
      ];
    };
  };

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    3100  # Loki
    9080  # Promtail
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    loki
    promtail
  ];
}
