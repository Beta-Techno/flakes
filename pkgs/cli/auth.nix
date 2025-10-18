{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "auth";
    runtimeInputs = with pkgs; [
      github-cli
      jq
      xclip
      git
      gawk        # for awk
      openssh     # for ssh-keygen
    ];

    text = ''
      set -euo pipefail

      # ── Configuration ────────────────────────────────────────────
      KEY_PATH="$HOME/.ssh/id_ed25519"

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
          echo "  Choose your preferred authentication method:"
          echo "  1) Open browser automatically"
          echo "  2) Use token authentication"
          read -rp "  Enter choice [1-2]: " auth_choice

          case "''${auth_choice}" in
            1)
              echo "  Attempting to open browser..."
              if ! gh auth login --hostname github.com --web; then
                die "Failed to open browser. Please try another method."
              fi
              ;;
            2)
              echo "  Please enter your GitHub token:"
              read -rsp "  Token: " token
              echo
              if ! gh auth login --hostname github.com --with-token <<<"$token"; then
                die "Failed to authenticate with token. Please try again."
              fi
              ;;
            *)
              die "Invalid choice. Please try again."
              ;;
          esac

          # Verify authentication worked
          if ! gh auth status &>/dev/null; then
            die "GitHub authentication failed. Please try again."
          fi
          
          echo "✅  GitHub authentication successful"
        fi

        # Upload key if missing
        fingerprint="$(ssh-keygen -lf "''${KEY_PATH}.pub" | awk '{print $2}')"
        if ! gh ssh-key list --json fingerprint | jq -e ".[] | select(.fingerprint==\"''${fingerprint}\")" >/dev/null; then
          echo "+ uploading SSH key to GitHub"
          if ! gh ssh-key add "''${KEY_PATH}.pub" -t "$(hostname)"; then
            die "Failed to upload SSH key to GitHub"
          fi
        fi
      fi

      # ── Git identity ─────────────────────────────────────────────
      # Always prompt for git identity (override NixOS defaults)
      read -rp "Git user.name  : " git_name
      read -rp "Git user.email : " git_email
      git config --global user.name  "$git_name"
      git config --global user.email "$git_email"

      echo "✅  Authentication complete"
    '';
  };
} 