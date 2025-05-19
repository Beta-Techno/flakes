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

      # ── Activate configuration ───────────────────────────────────
      echo "+ activating Home-Manager configuration"
      home-manager switch

      echo "✅  Activation complete"
    '';
  };
} 