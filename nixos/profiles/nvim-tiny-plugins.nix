# nixos/profiles/nvim-tiny-plugins.nix
{ pkgs, ... }:
{
  programs.neovim.configure = {
    customRC = ''
      " Ensure line numbers are set (in case core config is overridden)
      set number
      set relativenumber
    '';
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
