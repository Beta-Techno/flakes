# =============================
#  flake.nix  — clean, single‑system + bootstrap helper
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

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    let
      # Use the system we are evaluating on (falls back to x86_64‑linux if undefined)
      hostSystem = builtins.getEnv "NIX_SYSTEM" or null;
      mySystem   = if hostSystem != null && hostSystem != "" then hostSystem else "x86_64-linux";
      pkgs       = import nixpkgs { system = mySystem; config.allowUnfree = true; };
    in
    {
      # Home‑Manager config that `home-manager switch --flake .#rob` expects
      homeConfigurations.rob = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/dev.nix ];
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; }; in
      {
        packages.bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
          set -euo pipefail
          nix run github:nix-community/home-manager/release-24.05 --extra-experimental-features 'nix-command flakes' -- --flake ${self.url or "."}#rob
        '';
      });
}