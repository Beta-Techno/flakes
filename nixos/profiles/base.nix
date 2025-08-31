{ config, pkgs, lib, ... }:

{
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages (needed for NVIDIA drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Boot configuration - DISABLED for macOS systems
  # macOS uses rEFInd boot manager, we should not configure boot loaders
  # boot.loader.systemd-boot.enable = false;
  # boot.loader.grub.enable = false;

  # Basic system configuration
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  # Basic security
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tmux
  ];

  # Users
  users.users.ops = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
    ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };
}

