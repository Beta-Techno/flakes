{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
  # Create a merged LazyVim configuration that ensures our imports are loaded first
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" { } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    chmod -R u+w $out  # Make files writable
    rm -f $out/lua/config/init.lua  # Remove the starter's init.lua that's causing the warning
    cp -R ${lazyvimConfig}/lua/plugins $out/lua/
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
