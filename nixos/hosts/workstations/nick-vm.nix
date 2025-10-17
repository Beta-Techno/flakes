{ config, pkgs, lib, inputs, ... }:

{
  # ── Nick VM Workstation Configuration ─────────────────────────────────────
  # This configuration provides a clean VM workstation setup with:
  # - Proper module import layering (no Home Manager modules at system level)
  # - VM-appropriate video drivers (overrides workstation role's Intel drivers)
  # - Chrome sandbox support via security.chromiumSuidSandbox.enable
  # - Consistent Home Manager state versioning (24.11)
  # - Common VM optimizations via profiles/virt.nix (QEMU guest, fstrim, etc.)
  # - General workstation role that can be overridden as needed
  imports = [
    # Base system configuration
    ../../profiles/base.nix
    
    # Development workstation profile
    ../../roles/workstation.nix
    
    # UEFI systemd-boot for Proxmox VMs
    ../../profiles/boot/uefi-sdboot.nix
    
    # Virtualization profile (QEMU guest, fstrim, VM optimizations)
    ../../profiles/virt.nix
    
    # Home-Manager NixOS module (required for home-manager.users)
    inputs.home-manager.nixosModules.home-manager
  ];

  # System configuration
  # Note: system.stateVersion is defined in the workstation role (23.11)

  # Force root and ESP mounts by LABEL (matches your disko spec)
  # This overrides disko-generated mounts to ensure stage-1 finds the correct devices
  fileSystems."/" = lib.mkForce {
    device  = "/dev/disk/by-label/nixos";  # disko sets -L nixos
    fsType  = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = lib.mkForce {
    device  = "/dev/disk/by-label/EFI";    # disko sets -n EFI on the ESP
    fsType  = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # VM-specific configurations are now handled by ../../profiles/virt.nix

  # Chrome sandbox (fix "chrome won't start" on NixOS with google-chrome)
  # Covers chromium/google-chrome setuid sandbox in a supported way.
  security.chromiumSuidSandbox.enable = true;

  # (Optional) keep NixOS docs off on a slim VM; comment out if you rely on them
  # documentation.nixos.enable = lib.mkDefault false;

  # Guest/trim niceties are now handled by ../../profiles/virt.nix

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
      # VM‑centric stack — overrides role's mkDefault "intel" driver
      # Works well on Proxmox/QEMU with virtio‑gpu; vmware covers ESXi guests.
      videoDrivers = [ "modesetting" "virtio" "vmware" ];
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
    
    # Home-Manager version (use a real/current HM release tag)
    home.stateVersion = "24.11";
    
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
      inherit (inputs) nixGL lazyvimStarter lazyvimConfig doomConfig nix-doom;
      helpers = import ../../../modules/lib/helpers.nix { inherit pkgs lib; };
      username = "nbg";
    };
  };

  # Virtualization optimizations
  virtualisation = {
    # Enable Docker
    docker.enable = true;
    # Guest tools (vmware/virtualbox) are handled by ../../profiles/virt.nix
  };

  # Security and performance
  security = {
    # Enable real-time kit for audio
    rtkit.enable = true;
    
    # Sudo configuration
    sudo.wheelNeedsPassword = false;
  };

  # System optimizations for VM are now handled by ../../profiles/virt.nix
}
