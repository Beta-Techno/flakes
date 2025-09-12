# Netbox host configuration
{ config, lib, pkgs, ... }:

{
  # Network configuration (DHCP for simplicity and reliability)
  networking.useDHCP = true;

  # Filesystems (UEFI needs a real ESP mounted at /boot)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Bootloader configuration for VM (UEFI + systemd-boot)
  imports = [ ../../profiles/boot/uefi-sdboot.nix ];

  # Make sure initrd has virtio drivers in VMs to avoid early root mount races
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  # Pin system state version
  system.stateVersion = "24.11";

  # PostgreSQL: disable TLS until certs exist (prevents boot failures)
  services.postgresql.settings.ssl = lib.mkForce false;

  # Enable zsh for the user
  programs.zsh.enable = true;

  # Create your login on this server
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    
    # One-time password (change this after first login!)
    initialPassword = "TempPass1@3$";
    
    # Add your SSH key here for secure access
    openssh.authorizedKeys.keys = [
      # Replace with your actual SSH public key
      # "ssh-ed25519 AAAA...your_key..."
    ];
  };

  # Netbox-specific overrides - catch-all for any IP/hostname
  services.nginx.virtualHosts."netbox.local" = {
    default = true;  # catch-all for any Host/IP on :80
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
      extraConfig = ''
        # Present a consistent Host to Django so ALLOWED_HOSTS is simple
        proxy_set_header Host netbox.local;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  # System-specific packages
  environment.systemPackages = with pkgs; [
    # Netbox-specific tools (using container, not packaged version)
    postgresql_15
    pgcli
  ];
}
