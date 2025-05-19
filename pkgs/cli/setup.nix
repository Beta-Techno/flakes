{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "setup";
    runtimeInputs = with pkgs; [
      nix
      home-manager
      git
      github-cli  # for gh auth status
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

      # ── Install auth tool first ──────────────────────────────────
      echo "+ installing auth tool"
      nix profile install .#auth

      # ── Check GitHub authentication ──────────────────────────────
      if ! gh auth status &>/dev/null; then
        echo "+ running auth tool"
        auth || die "GitHub authentication failed. Please try again"
      fi

      # ── Install development shells ───────────────────────────────
      echo "+ installing development shells"
      nix profile install .#rust
      nix profile install .#go
      nix profile install .#python

      # ── Install helper CLIs ──────────────────────────────────────
      echo "+ installing helper CLIs"
      nix profile install .#sync-repos
      nix profile install .#doctor

      # ── Set up user configuration ────────────────────────────────
      CONFIG_DIR="$HOME/.config/toolbox"
      mkdir -p "''${CONFIG_DIR}"
      
      # Store GitHub username for later use
      git config --global --get user.email > "''${CONFIG_DIR}/username"

      echo "✅  Setup complete"
    '';
  };
} 