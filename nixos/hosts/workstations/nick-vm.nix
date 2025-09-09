{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Base system configuration
    ../../profiles/base.nix
    
    # Development workstation profile
    ../../roles/workstation.nix
    
    # UEFI systemd-boot for Proxmox VMs
    ../../profiles/boot/uefi-sdboot.nix
    
    # Home-Manager NixOS module (required for home-manager.users)
    inputs.home-manager.nixosModules.home-manager
    
    # Platform-specific modules (system-level only)
    ../../../modules/platform/linux/desktop/gnome.nix
  ];

  # System configuration
  # Note: system.stateVersion is defined in the workstation role (23.11)

  # Mounts are provided by disko (no fileSystems.* here)

  # VM-specific hardware configuration
  hardware = {
    # Enable redistributable firmware for virtual devices
    enableRedistributableFirmware = true;
    
    # Virtual graphics support
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Boot configuration for VM
  boot = {
    # Load virtual graphics modules
    kernelModules = [ "virtio" "virtio_pci" "virtio_net" "virtio_blk" ];
    
    # Kernel parameters for VM optimization
    kernelParams = [
      "console=ttyS0"
      "nokaslr"
      "iommu=off"
    ];
    
    # Bootloader configuration is handled by uefi-sdboot.nix profile
  };

  # Guest/trim niceties
  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  # Network configuration for VM
  networking = {
    # Use NetworkManager for network management
    networkmanager = {
      enable = true;
      wifi.backend = "wpa_supplicant";
      wifi.powersave = true;
    };
    
    # Disable global wireless service (use NetworkManager instead)
    wireless.enable = false;
    
    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 8080 3000 5000 ];
      allowedUDPPorts = [ 53 67 68 ];
    };
  };

  # Display and desktop configuration
  services = {
    # Enable X server
    xserver = {
      enable = true;
      
      # Virtual graphics configuration
      videoDrivers = [ "modesetting" "vmware" "virtio" ];
    };
    
    # Enable PipeWire for audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  # User configuration
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Enable zsh as default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # System packages for VM
  environment.systemPackages = with pkgs; [
    # System utilities
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
    
    # Terminal tools
    tmux
    zsh
    
    # File management
    ranger
    mc
    ncdu
    duf
    
    # Monitoring
    iotop
    nethogs
    btop
    
    # GUI applications (system-level)
    vscode
    postman
    google-chrome
    
    # JetBrains tools (system-level, like nick-laptop)
    jetbrains.datagrip
    jetbrains.rider
    
    # Fonts (system-level)
    nerd-fonts.jetbrains-mono
    
    # CLI tools from our flake
    (import ../../../pkgs/cli/activate.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/auth.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/setup.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/sync-repos.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/doctor.nix { inherit pkgs; }).program
  ];

  # Home-Manager configuration
  home-manager.users.nbg = { pkgs, ... }: {
    imports = [
      # GUI modules (contains theme, dock, and other user preferences)
      ../../../modules/gui/default.nix
      
      # Terminal configuration (contains Alacritty user config)
      ../../../modules/terminal/default.nix
      
      # Editor configurations (contains LazyVim and Doom Emacs user config)
      ../../../modules/editors/default.nix
      
      # Development tools (contains user-specific tool configs)
      ../../../modules/tools/default.nix
      
      # Platform-specific modules (contains user-specific platform configs)
      ../../../modules/platform/linux/default.nix
    ];
    
    # Home-Manager version
    home.stateVersion = "25.11";
    
    # Home directory packages (development environment)
    # Use toolsets for clean, DRY package management (same as nick-laptop)
    home.packages = let 
      t = import ../../../nix/toolsets.nix { inherit pkgs; lib = pkgs.lib; };
    in t.devAll;

    # Development shell aliases
    home.shellAliases = {
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      gs = "git status";
      gp = "git pull";
      gc = "git commit -m";
    };

    # Pass required arguments to modules
    _module.args = {
      inherit (inputs) nixGL lazyvimStarter lazyvimConfig doomConfig;
      helpers = import ../../../modules/lib/helpers.nix { inherit pkgs lib; };
      username = "nbg";
    };
  };

  # Virtualization optimizations
  virtualisation = {
    # Enable Docker
    docker.enable = true;
    
    # VM guest tools (if using VMware)
    vmware.guest.enable = lib.mkDefault false;
    
    # VirtualBox guest tools (if using VirtualBox)
    virtualbox.guest.enable = lib.mkDefault false;
  };

  # Security and performance
  security = {
    # Enable real-time kit for audio
    rtkit.enable = true;
    
    # Sudo configuration
    sudo.wheelNeedsPassword = false;
  };

  # System optimizations for VM
  systemd = {
    # Optimize for VM environment
    services.NetworkManager-wait-online.serviceConfig = {
      ExecStart = [ "" "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any" ];
    };
  };
}
