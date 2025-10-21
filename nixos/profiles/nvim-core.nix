# nixos/profiles/nvim-core.nix
{ lib, pkgs, ... }:
{
  programs.neovim = {
    enable = true;           # installs nvim the "module way"
    defaultEditor = true;    # set EDITOR/VISUAL to nvim
    viAlias = true;          # vi -> nvim
    vimAlias = true;         # vim -> nvim

    # keep server binary lean; enable providers later if you need them
    withPython3 = false;
    withNodeJs  = false;
    withRuby    = false;

    # small, safe defaults – no plugins here
    extraConfig = ''
      let g:mapleader = " "
      set number
      set relativenumber
      set mouse=a
      set termguicolors
      set ignorecase
      set smartcase
      set expandtab
      set shiftwidth=2
      set tabstop=2
      nnoremap <leader>w :write<CR>
      nnoremap <leader>q :quit<CR>
    '';
  };
}
