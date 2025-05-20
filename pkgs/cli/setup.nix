{ pkgs, flakeRef }:

{
  program = pkgs.writeShellApplication {
    name = "setup";
    runtimeInputs = with pkgs; [
      nix
      home-manager
      git
      github-cli
      xdg-utils  # for browser opening on Linux
    ];

    text = ''
      set -euo pipefail

      # Get the flake reference
      FLAKE="${flakeRef}"

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
      echo "▶ Checking GitHub authentication…"
      if ! gh auth status >/dev/null 2>&1; then
        echo "🔑  Opening browser to authenticate your personal account"
        if ! gh auth login --git-protocol ssh --web; then
          die "GitHub authentication failed. Please try again."
        fi
      fi

      # ── Install development shells ───────────────────────────────
      echo "▶ Installing development shells"
      for lang in rust go python; do
        echo "+ installing $lang toolchain"
        nix profile install "$FLAKE"#"$lang" --impure -L || die "Failed to install $lang toolchain"
      done

      # ── Install helper CLIs ──────────────────────────────────────
      echo "▶ Installing helper CLIs"
      for tool in sync-repos doctor; do
        echo "+ installing $tool"
        nix profile install "$FLAKE"#"$tool" --impure -L || die "Failed to install $tool"
      done

      # ── Set up user configuration ────────────────────────────────
      CONFIG_DIR="$HOME/.config/toolbox"
      mkdir -p "''${CONFIG_DIR}"
      
      # Store GitHub username for later use
      git_email="$(git config --global --get user.email || true)"
      if [ -z "''${git_email}" ]; then
        read -rp "Git user.email: " git_email
        git config --global user.email "$git_email"
      fi
      echo "$git_email" > "''${CONFIG_DIR}/username"

      echo "✅  Setup complete"
    '';
  };
} 