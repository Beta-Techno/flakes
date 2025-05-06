{
  /* ====================================================================
     Nick's declarative workstation setup — STABLE CHANNEL ONLY
     ==================================================================== */
  description = "Nick's declarative workstation setup (stable 24.05)";

  inputs = {
    # --------------------------------------------------------------------
    # Primary package source: nixpkgs stable branch (24.05)
    # --------------------------------------------------------------------
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Home‑Manager pinned to the matching release for maximal compatibility
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      # Share the nixpkgs input so both use the exact same revision
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helper library for multi‑system outputs (x86_64-linux, aarch64-darwin…)
    flake-utils.url = "github:numtide/flake-utils";
  };

  /* ====================================================================
     Outputs — one attrset per target system
     ==================================================================== */
  outputs = { self, nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Import nixpkgs for this CPU/OS; allow unfree for VS Code, Chrome…
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        /* ---------------------------------------------------------------
           1. Bootstrap helper
           ---------------------------------------------------------------
           Run this on a fresh box (after installing Nix):

             nix run github:<your‑gh>/dotfiles#bootstrap

           It will pull Home‑Manager, apply the 'nick' configuration, and
           leave you in a fully set‑up shell.
        */
        packages.bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
          set -euo pipefail

          if ! command -v nix >/dev/null; then
            echo "‼  Nix is not installed. Aborting." >&2
            exit 1
          fi

          # Apply the Home‑Manager configuration defined below
          nix run home-manager/master -- \
            init --switch --flake ${self.url or "."}#rob
        '';

        /* ---------------------------------------------------------------
           2. Home‑Manager configuration (user scope)
           ---------------------------------------------------------------
           The heavy lifting happens in ./home/dev.nix — edit that file
           to add packages, dot‑files, and systemd user services.
        */
        homeConfigurations.rob = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/dev.nix ];
        };
      });
}
