{ config, pkgs, lib, inputs, ... }:

{
  imports = [ 
    ../../roles/workstation.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Host-specific configuration
  networking.hostName = "nick-laptop";
  networking.domain = "example.com";

  # Network configuration - DISABLED to prevent WiFi issues
  # networking.interfaces.wlan0 = {
  #   useDHCP = true;
  # };

  # File systems (configured for your actual system)
  fileSystems."/" = {
    device = "/dev/sda2";  # Root filesystem (same as /nix/store)
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda1";  # Boot partition (vfat)
    fsType = "vfat";
  };

  # Note: /nix/store is a subvolume of the root filesystem
  # No separate mount point needed

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
    # Enable graphics with Intel video acceleration
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver vaapiIntel vaapiVdpau libvdpau-va-gl ];
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

  # System packages - Full development environment
  environment.systemPackages = with pkgs; [
    # Development tools
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
    
    # Python development
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.poetry-core
    ruff
    black
    mypy
    python3Packages.pylint
    python3Packages.pytest
    python3Packages.pytest-cov
    python3Packages.ipython
    python3Packages.jupyter
    python3Packages.python-lsp-server
    
    # Rust development
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    cargo-edit
    cargo-outdated
    cargo-udeps
    cargo-watch
    cargo-expand
    cargo-audit
    cargo-deny
    cargo-msrv
    cargo-nextest
    cargo-tarpaulin
    
    # Go development
    go
    gopls
    gotools
    
    # Node.js development
    nodejs
    nodePackages.npm
    nodePackages.yarn
    
    # Additional development tools
    gcc
    gnumake
    cmake
    pkg-config
    
    # System utilities
    brightnessctl
    htop
    tree
    ripgrep
    fzf
    jq
    curl
    wget
    unzip
    zip
    rsync
    sshfs
    fuse
    
    # Network tools
    inetutils
    mtr
    iperf3
    nmap
    
    # Container tools
    docker
    docker-compose
    kubectl
    helm
    
    # Version control
    git
    git-lfs
    gh  # GitHub CLI
    
    # Text editors
    vim
    neovim
    emacs
    
    # Terminal tools
    tmux
    zsh
    oh-my-zsh
    
    # File management
    ranger
    mc
    ncdu
    duf
    
    # Monitoring
    htop
    iotop
    nethogs
    btop
  ];

  # Enable flatpak for additional applications
  # services.flatpak.enable = true; # Already enabled in workstation role
  
  # Add CLI tools to system packages
  environment.systemPackages = environment.systemPackages ++ [
    # CLI tools from our flake
    (import ../../pkgs/cli/activate.nix { inherit pkgs; }).program
    (import ../../pkgs/cli/auth.nix { inherit pkgs; }).program
    (import ../../pkgs/cli/setup.nix { inherit pkgs; }).program
    (import ../../pkgs/cli/sync-repos.nix { inherit pkgs; }).program
    (import ../../pkgs/cli/doctor.nix { inherit pkgs; }).program
  ];

  # Enable automatic updates - DISABLED for safety
  # system.autoUpgrade = {
  #   enable = true;
  #   channel = "https://nixos.org/channels/nixos-23.11";
  # };
}

