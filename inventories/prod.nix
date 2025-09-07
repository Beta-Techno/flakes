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

  # Media services host
  media-01 = {
    system = "x86_64-linux";
    role = "media";
    ip = "10.0.0.12";
    hostModule = ./../nixos/hosts/servers/media-01.nix;
    modules = [ ];
  };

  # Database server host
  db-server-01 = {
    system = "x86_64-linux";
    role = "db-server";
    ip = "10.0.0.13";
    hostModule = ./../nixos/hosts/servers/db-server-01.nix;
    modules = [ ];
  };

  # Applications host
  applications-01 = {
    system = "x86_64-linux";
    role = "apps";
    ip = "10.0.0.14";
    hostModule = ./../nixos/hosts/servers/applications-01.nix;
    modules = [ ];
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
    modules = [ ];
  };
}
