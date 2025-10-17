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
    
    # User packages - Development environment (globally available for user)
    # Use toolsets for clean, DRY package management
    home.packages = let 
      t = import ../../../nix/toolsets.nix { inherit pkgs; lib = pkgs.lib; };
    in t.devAll;
    
    # ✅ merge all HM module imports here
    imports = [
      # editors (phase 2)
      ../../../modules/editors/lazyvim.nix
      ../../../modules/editors/doom.nix

      # GUI (phase 3) – use the aggregator
      ../../../modules/gui
      
      # Nix-Doom Emacs module
      inputs.nix-doom.homeModule
    ];

    # Doom Emacs configuration
    programs.doom-emacs = {
      enable = true;
      doomDir = inputs.doomConfig;  # Points to ./home/editors/doom
      doomLocalDir = "~/.local/share/nix-doom";  # Writable runtime dirs
      emacs = pkgs.emacs30-pgtk;
      extraPackages = epkgs: [
        epkgs.treesit-grammars.with-all-grammars
        epkgs.vterm
      ];
      # experimentalFetchTree = true;  # Enable if you hit "Cannot find Git revision" on newer Nix
      provideEmacs = true;  # Set false if you also want a separate vanilla Emacs
    };

    # Optional: Run Emacs as a user-level daemon
    services.emacs.enable = true;

    # pass args to editor modules
    _module.args = {
      inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nix-doom;
      username = "nbg";
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

    # --- Wi-Fi firmware & driver (Broadcom BCM43602 on MacBookPro12,1) ---
    # Be explicit so a fresh install always has the right bits available.
    enableRedistributableFirmware = true;
    firmware = [ pkgs.linux-firmware ];
  };

  # Kernel parameters for backlight control
  boot.kernelParams = [ "acpi_backlight=video" ];
  # Make sure the Broadcom driver is loaded early.
  boot.kernelModules = [ "brcmfmac" ];

  # Network configuration - ensure WiFi works
  networking = {
    # Use NetworkManager (it will run its own supplicant)
    networkmanager = {
      enable = true;
      # Good default for Broadcom; iwd is great but wpa_supplicant is safest here.
      wifi.backend = "wpa_supplicant";
      wifi.powersave = true;
      # Set your regulatory domain if you want: e.g. "US", "GB", "DE", ...
      # settings.wifi.country = "US";
    };
    # Do NOT enable the old global wireless service at the same time.
    wireless.enable = false;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 8080 3000 5000 ];
      allowedUDPPorts = [ 53 67 68 ];
    };
  };

  # Sound configuration (use PipeWire instead of PulseAudio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # System packages - All system-wide utilities and CLI tools
  environment.systemPackages = with pkgs; [
    # System utilities (hardware control, system management)
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
    
    # Network tools
    inetutils
    mtr
    iperf3
    nmap
    networkmanagerapplet  # WiFi management GUI
    
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
    # emacs removed - provided by Doom Emacs module
    
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
    
    # CLI tools from our flake
    (import ../../../pkgs/cli/activate.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/auth.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/setup.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/sync-repos.nix { inherit pkgs; }).program
    (import ../../../pkgs/cli/doctor.nix { inherit pkgs; }).program
    

  ];
  


  # Unblock wifi/bluetooth at boot in case firmware ships soft-blocked.
  systemd.services.unblock-rfkill = {
    description = "Unblock rfkill (WiFi/Bluetooth)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock all";
    };
  };

  # Enable NetworkManager applet for non-GNOME sessions
  programs.nm-applet.enable = true;

  # Enable automatic updates - DISABLED for safety
  # system.autoUpgrade = {
  #   enable = true;
  #   channel = "https://nixos.org/channels/nixos-23.11";
  # };
  

}

