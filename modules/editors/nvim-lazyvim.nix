{ lib, pkgs, lazyvimStarter, lazyvimConfig, ... }:

let
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" {
    passthru.starter = lazyvimStarter;
    passthru.config  = lazyvimConfig;
  } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    # overlay only the lua dir; your files win
    cp -R ${lazyvimConfig}/lua/* $out/lua/
  '';
in
{
  # 1) Neovim binary and helpers
  home.packages = with pkgs; [
    neovim
    ripgrep fd git gcc gnumake nodejs_20
  ];

  # 2) Single entry for the merged configuration
  xdg.configFile."nvim" = {
    source = lazyvimMerged;
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