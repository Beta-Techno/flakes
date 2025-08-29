{ config, pkgs, lib, ... }:

{
  # Enable Docker daemon
  virtualisation.docker = {
    enable = true;
    enableNvidia = false; # Set to true if you have NVIDIA GPU
  };

  # Add ops user to docker group
  users.users.ops.extraGroups = [ "docker" ];

  # Configure OCI containers (declarative containers)
  virtualisation.oci-containers = {
    backend = "docker";
    # Example container configuration
    # containers.myapp = {
    #   image = "nginx:latest";
    #   ports = [ "127.0.0.1:8080:80" ];
    #   restartPolicy = "always";
    # };
  };

  # Docker registry configuration
  virtualisation.docker.daemon.settings = {
    # Enable live restore for zero-downtime deployments
    live-restore = true;
    # Configure logging
    log-driver = "json-file";
    log-opts = {
      "max-size" = "10m";
      "max-file" = "3";
    };
  };
}

