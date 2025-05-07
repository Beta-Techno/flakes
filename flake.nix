# =============================
#  flake.nix — stable 24.05
# =============================
{
  description = "Rob's workstation flake (24.05)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    let
      system = "x86_64-linux";
      pkgs   = import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    {
      homeConfigurations.rob = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/dev.nix ];
      };
    } // flake-utils.lib.eachDefaultSystem (sys:
      let p = import nixpkgs { system = sys; config.allowUnfree = true; }; in
      {
        packages.bootstrap = p.writeShellScriptBin "bootstrap" ''
          set -euo pipefail
          nix run github:nix-community/home-manager/release-24.05 --extra-experimental-features 'nix-command flakes' -- --flake ${self.url or ""}#rob
        '';
      });
}