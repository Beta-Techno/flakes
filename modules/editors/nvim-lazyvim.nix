{ lib, pkgs, lazyvim, ... }:
{
  # 1) Neovim binary and helpers
  home.packages = with pkgs; [
    neovim
    ripgrep fd git gcc gnumake nodejs_20
  ];

  # 2) Drop the entire LazyVim tree into ~/.config/nvim (recursive = true)
  xdg.configFile."nvim" = {
    source = lazyvim;
    recursive = true;
  };

  # 3) Optional: auto-sync plugins right after home-manager switch
  home.activation.lazyvimSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v nvim >/dev/null; then
        echo "[LazyVim] Syncing plugins…"
        nvim --headless "+Lazy! sync" +qa || true
      fi
    '';
} 