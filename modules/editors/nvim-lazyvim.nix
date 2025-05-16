{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
  # Create a merged LazyVim configuration that ensures our imports are loaded first
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" { } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    chmod -R u+w $out  # Make files writable
    rm -rf $out/lua/plugins  # Remove all starter plugin specs
    mkdir -p $out/lua/plugins  # Recreate plugins directory
    cp -R ${lazyvimConfig}/lua/plugins/* $out/lua/plugins/  # Copy our plugin files
    cp -R ${lazyvimConfig}/lua/config $out/lua/
  '';
in
{
  home.packages = with pkgs; [
    neovim
    tree-sitter
    ripgrep
    fd
    lazygit
  ];

  xdg.configFile = {
    "nvim" = {
      source = lazyvimMerged;
      recursive = true;
    };
  };
}
