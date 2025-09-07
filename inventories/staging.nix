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

  # Staging media host
  staging-media-01 = {
    system = "x86_64-linux";
    role = "media";
    ip = "10.0.1.12";
    hostModule = ./../nixos/hosts/servers/media-01.nix;
    modules = [ ./../nixos/disko/media-01.nix ];
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
