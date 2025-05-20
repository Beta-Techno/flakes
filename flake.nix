{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvimStarter.url = "github:LazyVim/starter";
    lazyvimStarter.flake = false;
    lazyvimConfig = {
      url = "path:./home/editors/lazyvim";
      flake = false;
    };
    nix-doom.url = "github:marienz/nix-doom-emacs-unstraightened";
    doomConfig = {
      url = "path:./home/editors/doom";
      flake = false;
    };
    nixGL.url = "github:guibou/nixGL";
  };

  outputs = { self, nixpkgs, home-manager, nix-doom, nixGL, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
            "vscode"
            "google-chrome"
            "postman"
          ];
        };
      };
    in
    {
      # Expose configurations for nix eval and home.file use
      lazyvimConfig = inputs.lazyvimConfig;
      doomConfig = inputs.doomConfig;

      homeConfigurations = {
        macbook-air = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./profiles/default-darwin.nix
            ./hosts/macbook-air.nix
          ];
          extraSpecialArgs = {
            username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
            inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
          };
        };
        macbook-pro = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./profiles/default-darwin.nix
            ./hosts/macbook-pro.nix
          ];
          extraSpecialArgs = {
            username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
            inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
          };
        };
      };

      packages.${system} = {
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
        # CLI tools
        auth = (import ./pkgs/cli/auth.nix { inherit pkgs; }).program;
        setup = (import ./pkgs/cli/setup.nix { 
          inherit pkgs;
          flakeRef = builtins.toString self;
        }).program;
        sync-repos = (import ./pkgs/cli/sync-repos.nix { inherit pkgs; }).program;
        doctor = (import ./pkgs/cli/doctor.nix { inherit pkgs; }).program;
        activate = (import ./pkgs/cli/activate.nix { inherit pkgs; }).program;
      };
    };
} 