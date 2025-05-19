{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "auth";
    runtimeInputs = with pkgs; [
      github-cli
      jq
      xclip
      git
    ];

    text = ''
      set -euo pipefail

      # ── Configuration ────────────────────────────────────────────
      KEY_PATH="$HOME/.ssh/id_ed25519"
      GH_USER="$(git config --global --get user.email || true)"

      # ── Helper functions ─────────────────────────────────────────
      die() {
        echo "Error: $1" >&2
        exit 1
      }

      # ── GitHub authentication ────────────────────────────────────
      if [[ -n "''${GITHUB_TOKEN:-}" ]]; then
        echo "+ non-interactive GitHub auth (CI / server)"
        gh auth login --hostname github.com --with-token <<<"''${GITHUB_TOKEN}"
        
        # Configure git to use token for HTTPS
        git config --global url."https://''${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
      else
        echo "+ interactive developer auth"
        
        # Generate SSH key if missing
        if [ ! -f "''${KEY_PATH}.pub" ]; then
          echo "+ generating SSH key"
          ssh-keygen -t ed25519 -f "''${KEY_PATH}" -N "" -C "''${USER}@$(hostname)"
        fi

        # GitHub CLI auth
        if ! gh auth status &>/dev/null; then
          echo "+ authenticating with GitHub"
          gh auth login --hostname github.com --ssh --web
        fi

        # Upload key if missing
        fingerprint="$(ssh-keygen -lf ''${KEY_PATH}.pub | awk '{print $2}')"
        if ! gh ssh-key list --json fingerprint | jq -e ".[] | select(.fingerprint==\"''${fingerprint}\")" >/dev/null; then
          echo "+ uploading SSH key to GitHub"
          gh ssh-key add "''${KEY_PATH}.pub" -t "$(hostname)"
        fi
      fi

      # ── Git identity ─────────────────────────────────────────────
      if [ -z "''${GH_USER}" ]; then
        read -rp "Git user.name  : " git_name
        read -rp "Git user.email : " git_email
        git config --global user.name  "$git_name"
        git config --global user.email "$git_email"
      fi

      echo "✅  Authentication complete"
    '';
  };
} 