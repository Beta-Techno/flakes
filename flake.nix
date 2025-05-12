{
  description = "Rob's workstation flake (24.05)";

  inputs = {
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url  = "github:nix-community/home-manager/release-24.05";
    flake-utils.url   = "github:numtide/flake-utils";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgsFor = system: import nixpkgs { inherit system; config.allowUnfree = true; };
    pkgs = pkgsFor system;
    
    mkHM = { system, username ? builtins.getEnv "USER" }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor system;
        modules = [
          ./modules/common.nix
          ./hosts/${system}.nix
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
          }
        ];
      };
  in
  {
    homeConfigurations = {
      "${builtins.getEnv "USER"}@macbook-pro" = mkHM { system = "macbook-pro"; };
      "${builtins.getEnv "USER"}@macbook-air" = mkHM { system = "macbook-air"; };
    };

    packages.${system} = {
      # Machine detection script
      detect-machine = pkgs.writeShellScriptBin "detect-machine" ''
        set -euo pipefail
        if lscpu | grep -q "Intel(R) Core(TM) i7-4650U"; then
          echo "macbook-air"
        elif lscpu | grep -q "Intel(R) Core(TM) i5-5257U"; then
          echo "macbook-pro"
        else
          echo "unknown"
        fi
      '';

      # Bootstrap script
      bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
        set -euo pipefail

        # Run init script first
        if [ -f ./init.sh ]; then
          echo "Running init script..."
          bash ./init.sh
        fi

        # Detect machine type
        MACHINE=$(${pkgs.detect-machine}/bin/detect-machine)
        
        if [ "$MACHINE" = "unknown" ]; then
          echo "Unknown machine type. Please specify manually:"
          echo "1) MacBook Air (2014)"
          echo "2) MacBook Pro 13\" (2015)"
          read -p "Choose (1/2): " choice
          case $choice in
            1) MACHINE="macbook-air" ;;
            2) MACHINE="macbook-pro" ;;
            *) echo "Invalid choice"; exit 1 ;;
          esac
        else
          echo "Detected $MACHINE"
        fi

        echo "Applying configuration for $MACHINE..."
        nix run github:nix-community/home-manager/release-24.05 \
          --extra-experimental-features 'nix-command flakes' -- \
          switch --no-write-lock-file --flake .#"${USER}@$MACHINE"
      '';

      # Default package
      default = pkgs.writeShellScriptBin "default" ''
        echo "Please run one of the following commands:"
        echo "  nix run .#bootstrap"
        echo "  nix run .#detect-machine"
      '';
    };
  };
}