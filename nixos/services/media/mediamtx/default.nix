# MediaMTX service module
{ config, pkgs, lib, ... }:

{
  # MediaMTX container – use host networking; mount a single YAML file.
  virtualisation.oci-containers.containers.mediamtx = {
    image = "bluenviron/mediamtx:latest";
    volumes = [
      "/etc/mediamtx/mediamtx.yml:/mediamtx.yml:ro"
    ];
    environment = { TZ = "UTC"; };
    extraOptions = [
      "--network=host"
      # Let systemd handle restarts instead of Docker
    ];
  };

  # /etc/mediamtx/mediamtx.yml
  environment.etc."mediamtx/mediamtx.yml".text = ''
    logLevel: info
    logDestinations: [stdout]

    # Management - listen on all interfaces, no authentication
    api: yes
    apiAddress: :9997
    metrics: yes
    metricsAddress: :9998

    # Protocol listeners
    rtspAddress: :8554
    rtmpAddress: :1935
    hlsAddress: :8888
    webrtcAddress: :8889
    webrtcEncryption: no
    webrtcAllowOrigin: "*"

    # Authentication - disable for external access
    authMethod: none
    
    # Allow clients to publish any path
    paths:
      all:
        source: publisher
  '';

  # Optional local log directory (container logs go to stdout).
  systemd.tmpfiles.rules = [
    "d /var/log/mediamtx 0755 root root -"
  ];
}
