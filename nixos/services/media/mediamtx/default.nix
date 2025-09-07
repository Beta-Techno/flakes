# MediaMTX service module
{ config, pkgs, lib, ... }:

{
  # MediaMTX OCI container
  virtualisation.oci-containers.containers.mediamtx = {
    image = "bluenviron/mediamtx:latest";
    ports = [ "8554:8554" "1935:1935" ];
    
    volumes = [
      "/var/lib/mediamtx/config:/mediamtx.yml:ro"
    ];
    
    environment = {
      TZ = "UTC";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
    ];
  };

  # MediaMTX configuration
  environment.etc."mediamtx.yml".text = ''
    # MediaMTX configuration
    logLevel: info
    logDestinations: [stdout]
    logFile: /var/log/mediamtx/mediamtx.log
    
    # API configuration
    api: yes
    apiAddress: 0.0.0.0:9997
    
    # Metrics configuration
    metrics: yes
    metricsAddress: 0.0.0.0:9998
    
    # RTSP configuration
    rtspAddress: :8554
    rtspEncryption: "no"
    rtspServerKey: server.key
    rtspServerCert: server.crt
    
    # RTMP configuration
    rtmpAddress: :1935
    rtmpEncryption: "no"
    rtmpServerKey: server.key
    rtmpServerCert: server.crt
    
    # HLS configuration
    hlsAddress: :8888
    hlsEncryption: "no"
    hlsServerKey: server.key
    hlsServerCert: server.crt
    hlsAlwaysRemux: "no"
    hlsVariant: "lowLatency"
    hlsSegmentCount: 7
    hlsSegmentDuration: "1s"
    hlsPartDuration: "200ms"
    hlsSegmentMaxSize: "50M"
    
    # WebRTC configuration
    webrtcAddress: :8889
    webrtcEncryption: "no"
    webrtcServerKey: server.key
    webrtcServerCert: server.crt
    webrtcAllowOrigin: "*"
    
    # Paths configuration
    paths:
      all:
        source: publisher
        sourceOnDemand: "yes"
        sourceOnDemandStartTimeout: "10s"
        sourceOnDemandCloseAfter: "10s"
        sourceRedirect: ""
        disablePublisherOverride: "no"
        fallback: ""
        mux: gortsplib
        source: publisher
        sourceOnDemand: "yes"
        sourceOnDemandStartTimeout: "10s"
        sourceOnDemandCloseAfter: "10s"
        sourceRedirect: ""
        disablePublisherOverride: "no"
        fallback: ""
        mux: gortsplib
        runOnInit: ""
        runOnInitRestart: "no"
        runOnDemand: ""
        runOnDemandRestart: "no"
        runOnDemandStartTimeout: "10s"
        runOnDemandCloseAfter: "10s"
        runOnReady: ""
        runOnReadyRestart: "no"
        runOnRead: ""
        runOnReadRestart: "no"
        runOnUnread: ""
        runOnUnreadRestart: "no"
        runOnDemandStartTimeout: "10s"
        runOnDemandCloseAfter: "10s"
        runOnReady: ""
        runOnReadyRestart: "no"
        runOnRead: ""
        runOnReadRestart: "no"
        runOnUnread: ""
        runOnUnreadRestart: "no"
  '';

  # Create MediaMTX directories
  systemd.tmpfiles.rules = [
    "d /var/lib/mediamtx 0755 mediamtx mediamtx"
    "d /var/lib/mediamtx/config 0755 mediamtx mediamtx"
    "d /var/log/mediamtx 0755 mediamtx mediamtx"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    mediamtx
  ];
}
