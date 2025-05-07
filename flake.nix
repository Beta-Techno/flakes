# =============================
#  flake.nix
# =============================
{
  description = "Rob's declarative workstation (stable 24.05)";

  inputs = {
    # Stable channel pinned to 24.05 so updates stay reproducible
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Home‑Manager matching the same release
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Multi‑system helpers (not required, but convenient)
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # VS Code, Chrome, etc.
        };
      in
      {
        # -------------------------------------------------------------
        # Handy bootstrap script:  nix run .#bootstrap
        # -------------------------------------------------------------
        packages.bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
          set -euo pipefail
          echo "▶  Applying Home‑Manager flake configuration for user rob"
          nix run github:nix-community/home-manager/release-24.05 \
            --extra-experimental-features 'nix-command flakes' -- \
            --flake ${self.url or "."}#rob
        '';

        # -------------------------------------------------------------
        # Home‑Manager entry for user "rob"
        # -------------------------------------------------------------
        homeConfigurations.rob = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/dev.nix ];
        };
      });
}