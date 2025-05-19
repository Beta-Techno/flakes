{ pkgs, self }:

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

      # Absolute path to the flake that built this binary
      FLAKE="''${self}"

      # ── Helper functions ─────────────────────────────────────────
      die() {
        echo "Error: $1" >&2
        exit 1
      }

      # ── Check Nix installation ───────────────────────────────────
      if ! command -v nix >/dev/null 2>&1; then
        die "Nix is not installed"
      fi

      # ── Check GitHub authentication ──────────────────────────────
      if ! gh auth status &>/dev/null; then
        echo "+ running auth tool"
        
        # ── Ensure auth CLI is present and executable ───────────────
        AUTH_CMD="$(type -P auth || true)"   # like command -v but silent
        if ! [ -x "$AUTH_CMD" ]; then        # missing *or* non-executable
          echo "+ (re)installing auth"
          nix profile install "$FLAKE"#auth
          AUTH_CMD="$(type -P auth)"         # must succeed now
        fi

        echo "+ running auth"
        "$AUTH_CMD" || die "GitHub authentication failed. Please try again"
      fi

      # ── Install development shells ───────────────────────────────
      echo "+ installing development shells"
      nix profile install "$FLAKE"#rust
      nix profile install "$FLAKE"#go
      nix profile install "$FLAKE"#python

      # ── Install helper CLIs ──────────────────────────────────────
      echo "+ installing helper CLIs"
      nix profile install "$FLAKE"#sync-repos
      nix profile install "$FLAKE"#doctor

      # ── Set up user configuration ────────────────────────────────
      CONFIG_DIR="$HOME/.config/toolbox"
      mkdir -p "''${CONFIG_DIR}"
      
      # Store GitHub username for later use
      git config --global --get user.email > "''${CONFIG_DIR}/username"

      echo "✅  Setup complete"
    '';
  };
} 