{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
  ];

  # Workstation-specific settings
  system.stateVersion = "23.11";

  # Enable GUI
  services.xserver.enable = true;
  
  # Desktop environment
  services.desktopManager.gnome.enable = true;
  
  # Display manager
  services.displayManager.gdm.enable = true;
  
  # Video drivers
  services.xserver.videoDrivers = [ "intel" ]; # Intel driver for MacBook Pro 2015

  # Enable sound (PipeWire is configured in the host file)
  # Disable PulseAudio to avoid conflicts with PipeWire
  services.pulseaudio.enable = false;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable flatpak
  services.flatpak.enable = true;

  # Advanced system services
  services.prometheus.exporters.node.enable = true;
  services.grafana.enable = true;

  # Enable fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}

