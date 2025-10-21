# nixos/profiles/nvim-tiny-plugins.nix
{ pkgs, ... }:
{
  programs.neovim.configure = {
    packages.myVimPackage = {
      start = with pkgs.vimPlugins; [
        vim-sensible      # sane defaults
        vim-surround      # change surroundings easily
        vim-commentary    # gc to comment
        vim-fugitive      # :G status, blame, etc.
      ];
      opt = [ ];
    };
  };
}
