# Staging inventory - defines all staging hosts
{
  # Staging infrastructure host
  staging-infrastructure-01 = {
    system = "x86_64-linux";
    role = "infra";
    ip = "10.0.1.11";
    hostModule = ./../nixos/hosts/servers/infrastructure-01.nix;
    modules = [ ./../nixos/disko/infrastructure-01.nix ];
  };

  # Staging Jellyfin host (split from combined media role)
  staging-jellyfin-01 = {
    system = "x86_64-linux";
    role = "jellyfin-lite";
    ip = "10.0.1.12";
    hostModule = ./../nixos/hosts/servers/jellyfin-01.nix;
    modules = [ ];
  };

  # Staging MediaMTX host (split from combined media role)
  staging-mediamtx-01 = {
    system = "x86_64-linux";
    role = "mediamtx-lite";
    ip = "10.0.1.13";
    hostModule = ./../nixos/hosts/servers/mediamtx-01.nix;
    modules = [ ];
  };

  # Staging applications host
  staging-applications-01 = {
    system = "x86_64-linux";
    role = "apps";
    ip = "10.0.1.14";
    hostModule = ./../nixos/hosts/servers/applications-01.nix;
    modules = [ ./../nixos/disko/applications-01.nix ];
  };
}
