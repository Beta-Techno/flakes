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
      libN = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = pkg: builtins.elem (libN.getName pkg) [
            "vscode"
            "google-chrome"
            "postman"
          ];
        };
      };

      # Platform detection probes
      platform = {
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;
        isWSL = pkgs.stdenv.isLinux && builtins.pathExists "/proc/version" && 
                builtins.readFile "/proc/version" != "" && 
                builtins.match ".*Microsoft.*" (builtins.readFile "/proc/version") != null;
        hasSystemd = pkgs.stdenv.isLinux && !(pkgs.stdenv.isLinux && builtins.pathExists "/proc/version" && 
                    builtins.readFile "/proc/version" != "" && 
                    builtins.match ".*Microsoft.*" (builtins.readFile "/proc/version") != null);
        hasNvidia = pkgs.stdenv.isLinux && builtins.pathExists "/proc/driver/nvidia";
        hasAMD = pkgs.stdenv.isLinux && builtins.pathExists "/sys/class/drm/card0/device/vendor" && 
                 builtins.readFile "/sys/class/drm/card0/device/vendor" == "0x1002\n";
        hasGnome = pkgs.stdenv.isLinux && builtins.pathExists "/usr/bin/gnome-shell";
        hasKDE = pkgs.stdenv.isLinux && builtins.pathExists "/usr/bin/plasmashell";
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
            ./profiles/default-linux.nix
            ./hosts/macbook-air.nix
          ];
          extraSpecialArgs = {
            username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
            inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
            inherit platform;
          };
        };
        macbook-pro = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./profiles/default-linux.nix
            ./hosts/macbook-pro.nix
          ];
          extraSpecialArgs = {
            username = if builtins.getEnv "USERNAME" != "" then builtins.getEnv "USERNAME" else builtins.getEnv "USER";
            inherit (inputs) lazyvimStarter lazyvimConfig doomConfig nixGL;
            inherit platform;
          };
        };
      };

      packages.${system} = {
        detect-machine = pkgs.writeShellScriptBin "detect-machine" ''
          set -euo pipefail
          if [ -f /sys/class/dmi/id/product_name ]; then
            PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name)
            case "$PRODUCT_NAME" in
              "MacBookAir6,2")
                echo "macbook-air"
                ;;
              "MacBookPro12,1")
                echo "macbook-pro"
                ;;
              *)
                echo "unknown"
                ;;
            esac
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
        # Development shells
        rust = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            rustfmt
            clippy
          ];
        };
        go = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
          ];
        };
        python = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.virtualenv
          ];
        };
        # CLI tools
        auth = (import ./pkgs/cli/auth.nix { inherit pkgs; }).program;
        setup = (import ./pkgs/cli/setup.nix { 
          inherit pkgs;
        }).program;
        sync-repos = (import ./pkgs/cli/sync-repos.nix { inherit pkgs; }).program;
        doctor = (import ./pkgs/cli/doctor.nix { inherit pkgs; }).program;
        activate = (import ./pkgs/cli/activate.nix { inherit pkgs; }).program;
      };
    };
} 