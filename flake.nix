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
      # Support multiple systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper function to create packages for a system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Create pkgs for each system
      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg:
              let name =
                    if pkg ? pname then pkg.pname
                    else if pkg ? name then pkg.name
                    else "unknown";
              in builtins.elem name [ "vscode" "google-chrome" "postman" ];
            permittedInsecurePackages = [
              "nodejs-20.19.1"
            ];
          };
        }
      );


    in
    {
      # Expose configurations for nix eval and home.file use
      lazyvimConfig = inputs.lazyvimConfig;
      doomConfig = inputs.doomConfig;

      # Home-Manager configurations (for Ubuntu/macOS)
      homeConfigurations = forAllSystems (system:
        let pkgs = pkgsFor.${system};
        in {
          macbook-air = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./profiles/default-linux.nix
              ./home/hosts/macbook-air.nix
              nix-doom.hmModule
            ];
            extraSpecialArgs = {
              username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
              inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
            };
          };
          macbook-pro = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./profiles/default-linux.nix
              ./home/hosts/macbook-pro.nix
              nix-doom.hmModule
            ];
            extraSpecialArgs = {
              username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
              inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
            };
          };
        }
      );

      # NixOS configurations (for NixOS machines)
      nixosConfigurations = {
        # Server configurations
        web-01 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nixos/hosts/servers/web-01.nix ];
          specialArgs = { inherit inputs; };
        };
        db-01 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nixos/hosts/servers/db-01.nix ];
          specialArgs = { inherit inputs; };
        };
        
        # Workstation configurations
        nick-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nixos/hosts/workstations/nick-laptop.nix ];
          specialArgs = { inherit inputs; };
        };
      };

      packages = forAllSystems (system:
        let pkgs = pkgsFor.${system};
        in {
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
            detect_machine() {
              if [ -f /sys/class/dmi/id/product_name ]; then
                PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name)
                case "$PRODUCT_NAME" in
                  "MacBookAir6,2") echo "macbook-air" ;;
                  "MacBookPro12,1") echo "macbook-pro" ;;
                  *) echo "unknown" ;;
                esac
              else
                echo "unknown"
              fi
            }

            MACHINE=$(detect_machine)
            
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
            fi

            echo "Detected $MACHINE"

            # Set username (fall back to current user if not specified)
            USERNAME="''${USERNAME:-$USER}"

            # Build and activate the configuration
            echo "Building configuration for $USERNAME on $MACHINE..."
            export USERNAME
            SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem')
            nix run .#homeConfigurations."''${SYSTEM}"."''${MACHINE}".activationPackage --impure
          '';
          # Installable toolchain bundles
          toolchain-all = pkgs.buildEnv { 
            name = "toolchain-all";  
            paths = (import ./nix/toolsets.nix { inherit pkgs lib; }).devAll; 
          };
          toolchain-ci = pkgs.buildEnv { 
            name = "toolchain-ci";   
            paths = (import ./nix/toolsets.nix { inherit pkgs lib; }).ciLean; 
          };
          # CLI tools
          auth = (import ./pkgs/cli/auth.nix { inherit pkgs; }).program;
          setup = (import ./pkgs/cli/setup.nix { 
            inherit pkgs;
          }).program;
          sync-repos = (import ./pkgs/cli/sync-repos.nix { inherit pkgs; }).program;
          doctor = (import ./pkgs/cli/doctor.nix { inherit pkgs; }).program;
          activate = (import ./pkgs/cli/activate.nix { inherit pkgs; }).program;
        }
      );
      
      # Development shells (proper ephemeral environments)
      devShells = forAllSystems (system:
        let 
          pkgs = pkgsFor.${system};
          lib = nixpkgs.lib;
          t = import ./nix/toolsets.nix { inherit pkgs lib; };
        in {
          default = pkgs.mkShell { packages = t.devAll; };
          server = pkgs.mkShell { packages = t.common ++ t.go ++ t.rust; };
          go = pkgs.mkShell { packages = t.common ++ t.go; };
          rust = pkgs.mkShell { packages = t.common ++ t.rust; };
          node = pkgs.mkShell { packages = t.common ++ t.node; };
          python = pkgs.mkShell { packages = t.common ++ t.python; };
        }
      );
    };
} 