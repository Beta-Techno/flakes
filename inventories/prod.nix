# Production inventory - defines all production hosts
{
  # Netbox host (isolated)
  netbox-01 = {
    system = "x86_64-linux";
    role = "netbox";
    ip = "10.0.0.10";
    hostname = "nixos";  # Keep current hostname for testing
    hostModule = ./../nixos/hosts/servers/netbox-01.nix;
    modules = [ ];
  };

  # Infrastructure services host (monitoring)
  infrastructure-01 = {
    system = "x86_64-linux";
    role = "infra";
    ip = "10.0.0.11";
    hostModule = ./../nixos/hosts/servers/infrastructure-01.nix;
    modules = [ ];
  };

  # MediaMTX host (separate from Jellyfin)
  mediamtx-01 = {
    system = "x86_64-linux";
    role = "mediamtx-lite";
    ip = "10.0.0.12";
    hostModule = ./../nixos/hosts/servers/mediamtx-01.nix;
    modules = [ ];
  };

  # Jellyfin-only host (clean, minimal setup)
  jellyfin-01 = {
    system = "x86_64-linux";
    role = "jellyfin-lite";
    # If you'll run DHCP, you can omit ip; if static, set it here for your notes:
    # ip = "10.0.0.12";
    hostModule = ./../nixos/hosts/servers/jellyfin-01.nix;
    modules = [ ];
  };

  # PXE server host (network boot services)
  pxe-01 = {
    system = "x86_64-linux";
    role = "pxe-lite";
    # static IP optional; DHCP is fine for the first pass
    # ip = "10.0.0.15";
    hostModule = ./../nixos/hosts/servers/pxe-01.nix;
    modules = [ ];
  };

  # Media storage (NFS/SMB for Jellyfin/MediaMTX)
  storage-media-01 = {
    system = "x86_64-linux";
    role = "storage-media";
    ip = "10.0.0.16";
    hostModule = ./../nixos/hosts/servers/storage-media-01.nix;
    modules = [ ];
  };

  # Isolated backup target (push-only)
  storage-backup-01 = {
    system = "x86_64-linux";
    role = "storage-backup";
    ip = "10.0.2.118";
    hostModule = ./../nixos/hosts/servers/storage-backup-01.nix;
    modules = [ ];
  };

  # New: dedicated observability node
  observability-01 = {
    system = "x86_64-linux";
    role = "infra";
    # IP optional; we'll use DHCP to start. Keep a note if you want a fixed address later:
    # ip = "10.0.0.30";
    hostModule = ./../nixos/hosts/servers/observability-01.nix;
    modules = [ ];
  };

  # K3s Kubernetes cluster control plane
  k3s-01 = {
    system = "x86_64-linux";
    role = "k3s";
    ip = "10.0.0.31";
    hostname = "k3s-01";
    hostModule = ./../nixos/hosts/servers/k3s-01.nix;
    modules = [ ./../nixos/disko/k3s-vm.nix ];

    # K3s-specific configuration (consumed by roles/k3s.nix)
    k3s = {
      role = "server";
      clusterInit = true;          # first/only server
      disableServiceLB = false;    # keep k3s' built-in for day 1
      disableTraefik = true;       # disable since we have dedicated ingress-01
    };
  };

  # Development workstations (keep existing)
  nick-laptop = {
    system = "x86_64-linux";
    role = "workstation";
    ip = "10.0.0.20";
    hostModule = ./../nixos/hosts/workstations/nick-laptop.nix;
    modules = [ ];
  };

  nick-vm = {
    system = "x86_64-linux";
    role = "workstation";
    ip = "10.0.0.21";
    hostModule = ./../nixos/hosts/workstations/nick-vm.nix;
    modules = [ ./../nixos/disko/workstation-vm.nix ];
  };
}
