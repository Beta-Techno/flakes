# mkHost name cfg -> nixosSystem
# Core abstraction for creating NixOS systems from inventory definitions
{ inputs }:
name: cfg:
let
  inherit (inputs) nixpkgs home-manager nix-disko;
  system = cfg.system or "x86_64-linux";
  
  # Get host module from inventory (explicit path)
  hostModule = 
    if cfg ? hostModule then cfg.hostModule
    else builtins.abort "inventories.${name}.hostModule is required (path to nixos/hosts/... .nix)";
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs cfg; };
  modules = [
    # Role bundle (includes base.nix and other profiles)
    (import ./../../nixos/roles/${cfg.role}.nix)
    
    # Optional: disk layout (if using disko)
    (nix-disko.nixosModules.disko)
    
    # Host-specific module from inventory (explicit path)
    hostModule
    
    # Late bindings - set hostname from inventory (configurable)
    ({ lib, ... }: { networking.hostName = lib.mkDefault (cfg.hostname or name); })
    
    # Home-Manager integration (for development workstations)
    home-manager.nixosModules.home-manager
  ] ++ (cfg.modules or []);
}
