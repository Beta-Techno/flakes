{ lib, pkgs, doomEmacs, doomConfig, ... }:

{
  home.packages = with pkgs; [
    emacs30-pgtk
    ripgrep fd git gcc gnumake nodejs_20
  ];

  # Ensure XDG directories exist
  xdg.enable = true;

  # Put Doom in ~/.config/emacs
  xdg.configFile."emacs" = {
    source     = doomEmacs;
    recursive  = true;
    onChange   = ''
      echo "Copying Doom Emacs to $HOME/.config/emacs"
      ls -la $HOME/.config/emacs/bin || true
    '';
  };
  xdg.configFile."doom" = {
    source     = doomConfig;
    recursive  = true;
    onChange   = ''
      echo "Copying Doom config to $HOME/.config/doom"
      ls -la $HOME/.config/doom || true
    '';
  };

  # Adjust the activation script path:
  home.activation.doomSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    echo "Current directory structure:"
    ls -la "$HOME/.config" || true
    ls -la "$HOME/.config/emacs" || true

    # Ensure directories exist
    mkdir -p "$HOME/.config/emacs/bin"
    mkdir -p "$HOME/.config/doom"

    # Wait for xdg.configFile to finish copying
    sleep 1

    echo "After mkdir:"
    ls -la "$HOME/.config/emacs/bin" || true

    # Ensure the doom script is executable
    if [[ -f "$HOME/.config/emacs/bin/doom" ]]; then
      chmod +x "$HOME/.config/emacs/bin/doom"
      echo "Made doom script executable"
    else
      echo "Error: doom script not found at $HOME/.config/emacs/bin/doom"
      echo "Contents of $HOME/.config/emacs:"
      ls -la "$HOME/.config/emacs" || true
      exit 1
    fi

    # First-time setup
    if [[ ! -d "$HOME/.config/emacs/.local" ]]; then
      echo "[Doom] first-time install…"
      "$HOME/.config/emacs/bin/doom" install --yes
    else
      echo "[Doom] syncing…"
      "$HOME/.config/emacs/bin/doom" sync --yes
    fi
  '';

  programs.zsh.shellAliases = {
    doomsync = "$HOME/.config/emacs/bin/doom sync --yes";
    doomup   = "$HOME/.config/emacs/bin/doom upgrade --yes";
  };
} 