{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
  # Create a merged LazyVim configuration that ensures our imports are loaded first
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" { } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    chmod -R u+w $out  # Make files writable
    rm -rf $out/lua/plugins  # Drop all starter plugin specs
    mkdir -p $out/lua/plugins
    # Copy our imports file as init.lua to ensure it's loaded first
    cp ${lazyvimConfig}/lua/plugins/00-lazyvim-imports.lua $out/lua/plugins/init.lua
    # Copy the rest of our config
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
