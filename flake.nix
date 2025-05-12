{
  description = "Rob's workstation flake (24.05)";

  inputs = {
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url  = "github:nix-community/home-manager/release-24.05";
    flake-utils.url   = "github:numtide/flake-utils";
    # no nixGL overlay needed (wrapper pulls it at runtime)

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
  let
    system = "x86_64-linux";
    pkgs   = import nixpkgs { inherit system; config.allowUnfree = true; };
  in
  {
    homeConfigurations = {
      # MacBook Pro 13" (2015)
      macbook-pro = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/macbook-pro.nix ];
      };
      # MacBook Air (2014)
      macbook-air = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/macbook-air.nix ];
      };
    };
  }
  //
  flake-utils.lib.eachDefaultSystem (sys:
    let p = import nixpkgs { system = sys; config.allowUnfree = true; };
    in {
      packages = {
        # Machine detection script
        detect-machine = p.writeShellScriptBin "detect-machine" ''
          set -euo pipefail

          # Detect machine type
          if lscpu | grep -q "Intel(R) Core(TM) i7-4650U"; then
            echo "macbook-air"
          elif lscpu | grep -q "Intel(R) Core(TM) i5-5257U"; then
            echo "macbook-pro"
          else
            echo "unknown"
          fi
        '';

        # Bootstrap script
        bootstrap = p.writeShellScriptBin "bootstrap" ''
          set -euo pipefail

          # Run init script first
          if [ -f ./init.sh ]; then
            echo "Running init script..."
            bash ./init.sh
          fi

          echo "Applying configuration..."
          # Run directly from GitHub with --no-write-lock-file
          # Nix will automatically detect the correct machine configuration
          nix run github:nix-community/home-manager/release-24.05 \
            --extra-experimental-features 'nix-command flakes' -- \
            switch --no-write-lock-file --flake github:Beta-Techno/flakes
        '';
      };
    });
}