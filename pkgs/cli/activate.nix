{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "activate";
    runtimeInputs = with pkgs; [
      nix
      home-manager
    ];

    text = ''
      set -euo pipefail

      # ── Helper functions ─────────────────────────────────────────
      die() {
        echo "Error: $1" >&2
        exit 1
      }

      # ── Check Home-Manager ───────────────────────────────────────
      if ! command -v home-manager >/dev/null 2>&1; then
        die "Home-Manager is not installed"
      fi

      # ── Detect machine type ──────────────────────────────────────
      if [ -f /sys/class/dmi/id/product_name ]; then
        PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name)
        case "$PRODUCT_NAME" in
          "MacBookAir6,2")
            MACHINE="macbook-air"
            ;;
          "MacBookPro12,1")
            MACHINE="macbook-pro"
            ;;
          *)
            echo "Unknown machine type. Please specify manually:"
            echo "1) MacBook Air (2014)"
            echo "2) MacBook Pro 13\" (2015)"
            read -rp "Choose (1/2): " choice
            case $choice in
              1) MACHINE="macbook-air" ;;
              2) MACHINE="macbook-pro" ;;
              *) die "Invalid choice" ;;
            esac
            ;;
        esac
      else
        echo "Could not detect machine type. Please specify manually:"
        echo "1) MacBook Air (2014)"
        echo "2) MacBook Pro 13\" (2015)"
        read -rp "Choose (1/2): " choice
        case $choice in
          1) MACHINE="macbook-air" ;;
          2) MACHINE="macbook-pro" ;;
          *) die "Invalid choice" ;;
        esac
      fi

      # ── Activate configuration ───────────────────────────────────
      echo "+ activating Home-Manager configuration for $MACHINE"
      nix run ".#homeConfigurations.${MACHINE}.activationPackage" --impure --accept-flake-config

      echo "✅  Activation complete"
    '';
  };
} 