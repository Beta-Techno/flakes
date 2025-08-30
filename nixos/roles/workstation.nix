{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/docker-daemon.nix
  ];

  # Workstation-specific settings
  system.stateVersion = "23.11";

  # Enable GUI
  services.xserver = {
    enable = true;
    
    # Desktop environment
    desktopManager = {
      gnome.enable = true;
      xfce.enable = false;
    };
    
    # Display manager
    displayManager.gdm.enable = true;
    
    # Video drivers
    videoDrivers = [ "intel" ]; # Intel driver for MacBook Pro 2015
  };

  # Enable sound (PipeWire is configured in the host file)
  # Disable PulseAudio to avoid conflicts with PipeWire
  hardware.pulseaudio.enable = false;

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

  # System packages for workstation
  environment.systemPackages = with pkgs; [
    # GUI applications
    firefox
    chromium
    vscode
    gimp
    inkscape
    
    # Development tools
    git
    vim
    tmux
    htop
    tree
    
    # Media
    vlc
    spotify
  ];

  # Enable fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}

