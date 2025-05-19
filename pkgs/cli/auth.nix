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
          echo "  Choose your preferred authentication method:"
          echo "  1) Open browser automatically (may not work in all environments)"
          echo "  2) Copy URL to clipboard and open manually"
          echo "  3) Display URL to copy manually"
          read -rp "  Enter choice [1-3]: " auth_choice

          case "''${auth_choice}" in
            1)
              echo "  Attempting to open browser..."
              if ! gh auth login --hostname github.com --ssh --web; then
                die "Failed to open browser. Please try another method."
              fi
              ;;
            2)
              echo "  Copying URL to clipboard..."
              auth_url="$(gh auth login --hostname github.com --ssh --web --print-url)"
              echo "''${auth_url}" | xclip -selection clipboard
              echo "  URL copied to clipboard. Please open it in your browser."
              ;;
            3)
              echo "  Please visit this URL in your browser:"
              gh auth login --hostname github.com --ssh --web --print-url
              ;;
            *)
              die "Invalid choice. Please try again."
              ;;
          esac

          # Wait for user to complete authentication
          echo ""
          echo "  Please complete the authentication in your browser."
          echo "  Press Enter when done..."
          read -r

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