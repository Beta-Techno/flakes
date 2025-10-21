{ config, pkgs, lib, ... }:

{
  # Pick the boot profile that matches the machine:
  imports = [
    ../../profiles/boot/uefi-sdboot.nix
    # For legacy BIOS instead, comment the line above and uncomment:
    # ../../profiles/boot/bios-grub.nix
  ];

  system.stateVersion = "24.11";

  # Network & storage — keep it simple to start
  networking.useDHCP = true;

  # Make sure initrd has virtio drivers in VMs to avoid early root mount races
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  # If this is a freshly installed box with labels from your disko scripts:
  fileSystems."/" = lib.mkDefault {
    device  = "/dev/disk/by-label/nixos";
    fsType  = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = lib.mkDefault {
    device  = "/dev/disk/by-label/EFI";
    fsType  = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # OPTIONAL: nice-to-have reverse proxy (so you can browse http://media.local)
  services.nginx.virtualHosts."media.local" = {
    # keep this HTTP‑only for now; don't enable ACME on a .local name
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  # Convenience: a local admin user (adjust as you like)
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "render" ];
    shell = pkgs.zsh;
    
    # One-time password (change this after first login!)
    initialPassword = "TempPass1@3$";
    
    # Add your SSH key here for secure access
    openssh.authorizedKeys.keys = [
      # Replace with your actual SSH public key
      # "ssh-ed25519 AAAA...your_key..."
    ];
  };
  programs.zsh.enable = true;

  # Open the right ports at the host level as well (8096 + HTTP/S)
  networking.firewall.allowedTCPPorts = [ 8096 80 443 ];
}
