{ config, pkgs, lib, ... }:

{
  imports = [
    ./terminfo-ghostty.nix
  ];
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages (needed for NVIDIA drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Boot configuration - let roles/hosts choose their bootloader
  # Make base not pick a loader to avoid conflicts
  boot.loader.systemd-boot.enable = lib.mkDefault false;
  boot.loader.grub.enable = lib.mkDefault false;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;

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
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = "30s";
      X11Forwarding = false;
      AllowTcpForwarding = "no";
    };
  };

  # Basic security
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential text editors come from the Neovim module wrapper

    # Basic system tools
    htop
    tree
    ripgrep
    fzf
    jq
    curl
    wget
    git

    # Terminal multiplexer
    tmux

    # File management
    ranger
    ncdu
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

  # Authorize workstation keys everywhere that imports base.nix
  users.groups.nbg = lib.mkIf (builtins.pathExists ../keys/users/nbg.pub) {};
  users.users.nbg = lib.mkIf (builtins.pathExists ../keys/users/nbg.pub) {
    isNormalUser = true;
    group = "nbg";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ (builtins.readFile ../keys/users/nbg.pub) ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };
}

