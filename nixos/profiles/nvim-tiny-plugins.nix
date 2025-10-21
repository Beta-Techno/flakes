# nixos/profiles/nvim-tiny-plugins.nix
{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;                  # <— ensure the config is actually used
    defaultEditor = lib.mkDefault true;
    viAlias       = lib.mkDefault true;
    vimAlias      = lib.mkDefault true;

    configure = {
      customRC = ''
        " --- Numbers / UI -------------------------------------------------
        set number
        set relativenumber
        set termguicolors
        set signcolumn=yes

        " --- Transparent background (survives colorscheme) ---------------
        function! s:Transparent()
          highlight Normal         ctermbg=NONE guibg=NONE
          highlight NormalNC       ctermbg=NONE guibg=NONE
          highlight NonText        ctermbg=NONE guibg=NONE
          highlight LineNr         ctermbg=NONE guibg=NONE
          highlight CursorLine     ctermbg=NONE guibg=NONE
          highlight CursorLineNr   ctermbg=NONE guibg=NONE
          highlight SignColumn     ctermbg=NONE guibg=NONE
          highlight EndOfBuffer    ctermbg=NONE guibg=NONE
          highlight NormalFloat    ctermbg=NONE guibg=NONE
          highlight FloatBorder    ctermbg=NONE guibg=NONE
          highlight StatusLineNC   ctermbg=NONE guibg=NONE
          highlight Pmenu          ctermbg=NONE guibg=NONE
          highlight PmenuSbar      ctermbg=NONE guibg=NONE
          highlight PmenuThumb     ctermbg=NONE guibg=NONE
        endfunction
        augroup TransparentBG | autocmd!
          autocmd VimEnter,ColorScheme * call s:Transparent()
        augroup END
      '';

      packages.myVimPackage = {
        start = with pkgs.vimPlugins; [
          vim-sensible
          vim-surround
          vim-commentary
          vim-fugitive
        ];
        opt = [ ];
      };
    };
  };
}
