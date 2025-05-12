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
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in
  {
    homeConfigurations = {
      # MacBook Pro 13" (2015)
      macbook-pro = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-darwin"; config.allowUnfree = true; };
        modules = [ ./hosts/macbook-pro.nix ];
      };
      # MacBook Air (2014)
      macbook-air = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-darwin"; config.allowUnfree = true; };
        modules = [ ./hosts/macbook-air.nix ];
      };
    };
  }
  //
  flake-utils.lib.eachSystem supportedSystems (system:
    let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      packages = {
        # Machine detection script
        detect-machine = pkgs.writeShellScriptBin "detect-machine" ''
          set -euo pipefail
          if [[ "$OSTYPE" == "darwin"* ]]; then
            if sysctl -n machdep.cpu.brand_string | grep -q "Intel(R) Core(TM) i7-4650U"; then
              echo "macbook-air"
            elif sysctl -n machdep.cpu.brand_string | grep -q "Intel(R) Core(TM) i5-5257U"; then
              echo "macbook-pro"
            else
              echo "unknown"
            fi
          else
            if lscpu | grep -q "Intel(R) Core(TM) i7-4650U"; then
              echo "macbook-air"
            elif lscpu | grep -q "Intel(R) Core(TM) i5-5257U"; then
              echo "macbook-pro"
            else
              echo "unknown"
            fi
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
          MACHINE=$(${pkgs.writeShellScriptBin "detect-machine" ''
            set -euo pipefail
            if [[ "$OSTYPE" == "darwin"* ]]; then
              if sysctl -n machdep.cpu.brand_string | grep -q "Intel(R) Core(TM) i7-4650U"; then
                echo "macbook-air"
              elif sysctl -n machdep.cpu.brand_string | grep -q "Intel(R) Core(TM) i5-5257U"; then
                echo "macbook-pro"
              else
                echo "unknown"
              fi
            else
              if lscpu | grep -q "Intel(R) Core(TM) i7-4650U"; then
                echo "macbook-air"
              elif lscpu | grep -q "Intel(R) Core(TM) i5-5257U"; then
                echo "macbook-pro"
              else
                echo "unknown"
              fi
            fi
          ''}/bin/detect-machine)
          
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
            switch --no-write-lock-file --flake .#$MACHINE
        '';
      };
      # Add default package
      defaultPackage = pkgs.writeShellScriptBin "default" ''
        echo "Please run one of the following commands:"
        echo "  nix run github:Beta-Techno/flakes#bootstrap"
        echo "  nix run github:Beta-Techno/flakes#detect-machine"
      '';
    });
}