{
  description = "Rob's workstation flake (24.05)";

  inputs = {
    # Stable base (24.05)
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-24.05";

    # Latest channel just to grab alacritty-fhs (not in 24.05)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    flake-utils.url  = "github:numtide/flake-utils";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, flake-utils, ... }:
  let
    system        = "x86_64-linux";
    pkgs          = import nixpkgs          { inherit system; config.allowUnfree = true; };
    unstablePkgs  = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
  in
  {
    ##################################
    ## Home-Manager entry “rob”
    ##################################
    homeConfigurations.rob =
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # pass unstablePkgs into modules
        extraSpecialArgs = { unstable = unstablePkgs; };
        modules = [ ./home/dev.nix ];
      };
  }
  //
  ###########################################
  ## Convenience ‘nix run .#bootstrap’
  ###########################################
  flake-utils.lib.eachDefaultSystem (sys:
    let p = import nixpkgs { system = sys; config.allowUnfree = true; };
    in {
      packages.bootstrap = p.writeShellScriptBin "bootstrap" ''
        set -euo pipefail
        nix run github:nix-community/home-manager/release-24.05 \
          --extra-experimental-features 'nix-command flakes' -- \
          switch --flake ${self.url or "."}#rob
      '';
    });
}