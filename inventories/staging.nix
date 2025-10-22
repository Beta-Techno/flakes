# Staging inventory - defines all staging hosts
{

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

}
