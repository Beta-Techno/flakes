{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/boot/uefi-sdboot.nix
  ];

  system.stateVersion = "24.11";
  networking.useDHCP = true;
  networking.hostName = "observability-01";

  # Ensure virtio modules are present early (VM‑friendly)
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod" ];

  # Default root/ESP mounts by label (works with disko and our installers)
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

  # Convenience admin
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    initialPassword = "TempPass1@3$"; # change on first login
  };
  programs.zsh.enable = true;

  # Keep 22, 80, 443, plus Prom/Grafana/Loki
  networking.firewall.allowedTCPPorts = [ 22 80 443 9090 3000 3100 ];

  # Two simple vhosts for friendliness
  services.nginx.virtualHosts."observability.local" = {
    default = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000"; # Grafana
      proxyWebsockets = true;
    };
    locations."/prometheus/" = {
      proxyPass = "http://127.0.0.1:9090/";
      proxyWebsockets = true;
    };
    # exporter needs this:
    locations."/nginx_status".extraConfig = ''
      stub_status;
      allow 127.0.0.1;
      deny all;
    '';
  };

  environment.systemPackages = with pkgs; [
    curl jq htop
  ];
}
