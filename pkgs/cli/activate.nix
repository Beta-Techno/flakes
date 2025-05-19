{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "activate";
  runtimeInputs = with pkgs; [
    nix
    home-manager
    git
  ];

  text = ''
    set -euo pipefail

    # ── Helper functions ─────────────────────────────────────────
    die() {
      echo "Error: $1" >&2
      exit 1
    }

    # ── Check Nix installation ───────────────────────────────────
    if ! command -v nix >/dev/null 2>&1; then
      die "Nix is not installed"
    fi

    # ── Check Home-Manager ───────────────────────────────────────
    if ! command -v home-manager >/dev/null 2>&1; then
      die "Home-Manager is not installed"
    fi

    # ── Activate Home-Manager configuration ──────────────────────
    echo "+ activating Home-Manager configuration"
    home-manager switch

    echo "✅  Activation complete"
  '';
} 