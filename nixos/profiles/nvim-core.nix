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
    configure = {
      # Ensure our RC loads *after* any other customRC fragments
      customRC = lib.mkAfter ''
        let g:mapleader = " "
        set number
        set relativenumber
        set mouse=a
        set termguicolors
        set signcolumn=yes
        set ignorecase
        set smartcase
        set expandtab
        set shiftwidth=2
        set tabstop=2

        " --- Transparent background (and keep it after any colorscheme) ---
        function! s:Transparent()
          highlight Normal           ctermbg=NONE guibg=NONE
          highlight NormalNC         ctermbg=NONE guibg=NONE
          highlight NonText          ctermbg=NONE guibg=NONE
          highlight LineNr           ctermbg=NONE guibg=NONE
          highlight CursorLine       ctermbg=NONE guibg=NONE
          highlight CursorLineNr     ctermbg=NONE guibg=NONE
          highlight SignColumn       ctermbg=NONE guibg=NONE
          highlight EndOfBuffer      ctermbg=NONE guibg=NONE
          highlight NormalFloat      ctermbg=NONE guibg=NONE
          highlight FloatBorder      ctermbg=NONE guibg=NONE
          highlight StatusLineNC   ctermbg=NONE guibg=NONE
          highlight Pmenu            ctermbg=NONE guibg=NONE
          highlight PmenuSbar        ctermbg=NONE guibg=NONE
          highlight PmenuThumb       ctermbg=NONE guibg=NONE
        endfunction
        augroup TransparentBG | autocmd!
          autocmd VimEnter,ColorScheme * call s:Transparent()
        augroup END

        nnoremap <leader>w :write<CR>
        nnoremap <leader>q :quit<CR>
      '';
      packages.myVimPackage = {
        start = [ ];
        opt = [ ];
      };
    };
  };
}
