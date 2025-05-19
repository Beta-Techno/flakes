{ pkgs, lib }:

{
  program = pkgs.writeShellApplication {
    name = "doctor";
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

      check() {
        if ! "$@"; then
          echo "❌  $1 check failed"
          return 1
        else
          echo "✅  $1 check passed"
          return 0
        fi
      }

      # ── Check Nix installation ───────────────────────────────────
      echo "Checking Nix installation..."
      check nix --version
      check nix doctor

      # ── Check Home-Manager ───────────────────────────────────────
      echo "Checking Home-Manager..."
      check home-manager --version

      # ── Check Git configuration ──────────────────────────────────
      echo "Checking Git configuration..."
      check git --version
      check git config --global --get user.name
      check git config --global --get user.email

      # ── Check GitHub authentication ──────────────────────────────
      echo "Checking GitHub authentication..."
      check gh auth status

      # ── Check development shells ─────────────────────────────────
      echo "Checking development shells..."
      check nix profile list | grep -q "rust"
      check nix profile list | grep -q "go"
      check nix profile list | grep -q "python"

      # ── Check helper CLIs ────────────────────────────────────────
      echo "Checking helper CLIs..."
      check command -v sync-repos
      check command -v doctor
      check command -v activate

      echo "✅  All checks passed"
    '';
  };
} 