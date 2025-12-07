# Ingress-01 host configuration
# Single front door for all HTTP(S) traffic to Beta Technology infrastructure
{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # BOOT & HARDWARE
  # ============================================================================

  # UEFI boot with systemd-boot
  imports = [ ../../profiles/boot/uefi-sdboot.nix ];

  # Ensure virtio modules are present early (VM-friendly)
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  # ============================================================================
  # FILESYSTEMS
  # ============================================================================

  # Default root/ESP mounts by label (works with disko and manual installs)
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  # Static IP: 10.0.0.11 (configured in Proxmox or via DHCP reservation)
  # Using DHCP for initial simplicity; can switch to static if needed
  networking.useDHCP = true;
  networking.hostName = "ingress-01";

  # DNS resolution for backend services
  # (In production, these should be in DNS or /etc/hosts)
  networking.hosts = {
    "10.0.0.10" = [ "netbox-01" ];
    "10.0.0.30" = [ "observability-01" ];
    "10.0.0.31" = [ "k3s-01" ];
    # Jellyfin, MediaMTX, PXE use DHCP; add static entries if needed
    # Or use Tailscale MagicDNS for name resolution
  };

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  system.stateVersion = "24.11";

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  # Enable zsh for the admin user
  programs.zsh.enable = true;

  # Admin user (nbg)
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;

    # One-time password (CHANGE THIS after first login!)
    initialPassword = "TempPass1@3$";

    # SSH public key (add your actual key here)
    openssh.authorizedKeys.keys = [
      # Replace with your actual SSH public key
      # "ssh-ed25519 AAAA...your_key..."
    ];
  };

  # ============================================================================
  # FIREWALL
  # ============================================================================

  # HTTP/HTTPS ports are opened by the ingress role
  # SSH is only accessible via Tailscale (configured in base.nix)

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Essential tools for ingress debugging
    curl
    wget
    jq
    htop

    # Network diagnostics
    dnsutils
    tcpdump
    nmap

    # Text editors
    vim
    nano
  ];

  # ============================================================================
  # NOTES FOR DEPLOYMENT
  # ============================================================================

  # To deploy this host:
  # 1. Provision VM in Proxmox with:
  #    - 2 vCPU
  #    - 2GB RAM
  #    - 20GB disk
  #    - Network: vmbr0 (LAN bridge)
  #
  # 2. Install NixOS with basic config, then run:
  #    nixos-deploy ingress-01 -H root@10.0.0.11
  #
  # 3. Before deploying, ensure:
  #    - Cloudflare tunnel created in Zero Trust dashboard
  #    - Tunnel credentials JSON added to secrets/prod.yaml as cloudflared-beta-creds
  #    - DNS records (CNAME to tunnel) created for:
  #      - netbox.betatechnology.org
  #      - obs.betatechnology.org
  #      - media.betatechnology.org
  #      - stream.betatechnology.org
  #      - *.k8s.betatechnology.org
  #
  # 4. Verify deployment:
  #    curl -H "Host: netbox.local" http://10.0.0.11/api/status/
  #    curl https://netbox.betatechnology.org/api/status/
}
