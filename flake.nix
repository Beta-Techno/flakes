{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        # MacBook Air configuration
        macbook-air = 
          let username = (builtins.getEnv "USERNAME") or (builtins.getEnv "USER"); in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./modules/common.nix
              ./hosts/macbook-air.nix
            ];
            extraSpecialArgs = { inherit username; };
          };

        # MacBook Pro configuration
        macbook-pro = 
          let username = (builtins.getEnv "USERNAME") or (builtins.getEnv "USER"); in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./modules/common.nix
              ./hosts/macbook-pro.nix
            ];
            extraSpecialArgs = { inherit username; };
          };
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

          # Parse command line arguments
          USERNAME=""
          while [[ $# -gt 0 ]]; do
            case $1 in
              --user)
                USERNAME="$2"
                shift 2
                ;;
              *)
                echo "Unknown option: $1"
                echo "Usage: bootstrap [--user USERNAME]"
                exit 1
                ;;
            esac
          done

          # Run init script first
          if [ -f ./init.sh ]; then
            echo "Running init script..."
            bash ./init.sh
          fi

          # Detect machine type
          MACHINE=$(${self.packages.${system}.detect-machine}/bin/detect-machine)
          
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

          # Set username (fall back to current user if not specified)
          USERNAME="''${USERNAME:-$USER}"

          # Build and activate the configuration
          echo "Building configuration for $USERNAME on $MACHINE..."
          export USERNAME
          nix run .#homeConfigurations.''${MACHINE}.activationPackage --impure
        '';
      };
    };
}