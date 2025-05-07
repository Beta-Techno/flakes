# =============================
#  flake.nix
# =============================
{
  description = "Rob's declarative workstation (stable 24.05)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, flake-utils, ... }:
    let
      # Primary system you’re on right now. Home-Manager only needs one.
      defaultSystem = builtins.currentSystem;
      defaultPkgs   = import nixpkgs { inherit defaultSystem; config.allowUnfree = true; };
    in
    {
      # -----------------------------------------------------------
      # Home‑Manager entry searched by `home-manager switch --flake .#rob`
      # -----------------------------------------------------------
      homeConfigurations.rob = home-manager.lib.homeManagerConfiguration {
        pkgs    = defaultPkgs;
        modules = [ ./home/dev.nix ];
      };

      # -----------------------------------------------------------
      # Extra: bootstrap script available for *all* common systems
      # -----------------------------------------------------------
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in {
        packages.bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
          set -euo pipefail
          echo "▶  Applying Home‑Manager configuration for user rob"
          nix run github:nix-community/home-manager/release-24.05 --extra-experimental-features 'nix-command flakes' -- --flake ${self.url or ""}#rob
        '';
      });
}