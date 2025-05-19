{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "doctor";
  runtimeInputs = with pkgs; [
    nix
    home-manager
    git
    jq
  ];

  text = ''
    set -euo pipefail

    # ── Helper functions ─────────────────────────────────────────
    die() {
      echo "Error: $1" >&2
      exit 1
    }

    check() {
      local name="$1"
      local cmd="$2"
      local expected="$3"
      
      echo -n "Checking $name... "
      if eval "$cmd" | grep -q "$expected"; then
        echo "✅"
        return 0
      else
        echo "❌"
        return 1
      fi
    }

    # ── Check Nix installation ───────────────────────────────────
    echo "Checking Nix installation..."
    check "Nix version" "nix --version" "nix (Nix) 2"
    
    # Platform-specific Nix daemon check
    if [[ "$(uname)" == "Linux" ]]; then
      check "Nix daemon" "systemctl status nix-daemon 2>/dev/null || true" "active (running)"
    elif [[ "$(uname)" == "Darwin" ]]; then
      check "Nix daemon" "launchctl list | grep -q org.nixos.nix-daemon" "org.nixos.nix-daemon"
    fi

    # ── Check Home-Manager ───────────────────────────────────────
    echo "Checking Home-Manager..."
    check "Home-Manager version" "home-manager --version" "home-manager"
    check "Home-Manager generations" "home-manager generations" "generation"

    # ── Check Git configuration ──────────────────────────────────
    echo "Checking Git configuration..."
    check "Git user.name" "git config --global user.name" "."
    check "Git user.email" "git config --global user.email" "@"
    check "Git default branch" "git config --global init.defaultBranch" "main"

    # ── Check GitHub authentication ──────────────────────────────
    echo "Checking GitHub authentication..."
    if gh auth status &>/dev/null; then
      echo "GitHub authentication... ✅"
    else
      echo "GitHub authentication... ❌"
      echo "Run 'auth' to set up GitHub authentication"
    fi

    # ── Check development shells ─────────────────────────────────
    echo "Checking development shells..."
    check "Rust shell" "nix profile list | grep rust" "rust"
    check "Go shell" "nix profile list | grep go" "go"
    check "Python shell" "nix profile list | grep python" "python"

    # ── Check helper CLIs ────────────────────────────────────────
    echo "Checking helper CLIs..."
    check "sync-repos" "command -v sync-repos" "sync-repos"
    check "doctor" "command -v doctor" "doctor"

    echo "✅  Health check complete"
  '';
} 