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

  # Hardware-specific configuration
  hardware = {
    # Enable OpenGL
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
    
    # Enable pulseaudio
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  # System packages specific to this workstation
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
  ];

  # Enable flatpak for additional applications
  services.flatpak.enable = true;

  # Enable automatic updates
  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-23.11";
  };
}

