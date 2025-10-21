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
    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"
      vim.opt.termguicolors = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.keymap.set("n", "<leader>w", ":write<CR>", { silent = true })
      vim.keymap.set("n", "<leader>q", ":quit<CR>",  { silent = true })
    '';
  };
}
