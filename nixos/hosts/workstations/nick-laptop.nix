{ config, pkgs, lib, inputs, ... }:

{
  imports = [ 
    ../../roles/workstation.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Host-specific configuration
  networking.hostName = "nick-laptop";
  networking.domain = "example.com";

  # Network configuration
  networking.interfaces.wlan0 = {
    useDHCP = true;
  };

  # File systems (configured for your system)
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda11";
    fsType = "vfat";
  };

  fileSystems."/nix/store" = {
    device = "/dev/sda2";
    fsType = "ext4";
  };

  # Home-Manager configuration for the user
  home-manager.users.nbg = {
    home = {
      username = "nbg";
      homeDirectory = "/home/nbg";
      stateVersion = "24.05";
    };
    
    # Basic configuration
    fonts.fontconfig.enable = true;
    
    # Shell configuration
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
      };
    };
    
    # Common shell aliases
    home.shellAliases = {
      k = "kubectl";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
    };
    
    # System packages (will be installed in user environment)
    home.packages = with pkgs; [
      git
      vim
      tmux
      htop
      tree
      ripgrep
      fzf
      jq
      curl
      wget
    ];
  };

  # Create the user (if it doesn't exist)
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
    ];
  };

  # Enable zsh as default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Hardware-specific configuration for MacBook Pro 2015
  hardware = {
    # Enable OpenGL with Intel video acceleration
    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver vaapiIntel ];
    };
    
    # MacBook Pro specific settings
    cpu.intel.updateMicrocode = true;
  };

  # Kernel parameters for backlight control
  boot.kernelParams = [ "acpi_backlight=video" ];

  # Sound configuration (use PipeWire instead of PulseAudio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # System packages (merged from both definitions)
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    vim
    tmux
    htop
    tree
    
    # GUI applications
    firefox
    chromium
    vscode
    gimp
    inkscape
    
    # Media
    vlc
    spotify
    
    # System tools
    gnome.gnome-tweaks
    gnome.gnome-software
    
    # Brightness control
    brightnessctl
  ];

  # Enable flatpak for additional applications
  services.flatpak.enable = true;

  # Enable automatic updates
  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-23.11";
  };
}

