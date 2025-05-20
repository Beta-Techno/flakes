{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
  # Import shell configurations
  shells = import ../../pkgs/shells { inherit pkgs; };

  # Define our extras
  extras = ''
    -- 2 · all extras you want
    { import = \"lazyvim.plugins.extras.coding.yanky\" },
    { import = \"lazyvim.plugins.extras.dap.core\" },
    { import = \"lazyvim.plugins.extras.lang.json\" },
--    { import = \"lazyvim.plugins.extras.lang.markdown\" },
    { import = \"lazyvim.plugins.extras.lang.python\" },
    { import = \"lazyvim.plugins.extras.lang.rust\" },
    { import = \"lazyvim.plugins.extras.lang.typescript\" },
    { import = \"lazyvim.plugins.extras.lsp.none-ls\" },
--    { import = \"lazyvim.plugins.extras.ui.mini-animate\" },
--    { import = \"lazyvim.plugins.extras.util.mini-hipatterns\" },
  '';

  # Create a merged LazyVim configuration
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" { } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    chmod -R u+w $out

    # Insert our extras before the plugins import in lazy.lua
    sed -i "/{ import = \"plugins\" }/i ${builtins.replaceStrings ["\n"] ["\\n"] extras}" \
        $out/lua/config/lazy.lua

    # Set clipboard options in lazy.lua
    sed -i "/vim.g.mapleader = \" \"/a vim.opt.clipboard = \"unnamedplus\"\nvim.opt.clipboard:append(\"unnamed\")\nvim.opt.clipboard:append(\"autoselect\")" \
        $out/lua/config/lazy.lua

    # Remove any existing extras from plugins directory
    rm -f $out/lua/plugins/*extras*.lua

    # Copy our custom plugin files
    cp -R ${lazyvimConfig}/lua/plugins/* $out/lua/plugins/
    cp -R ${lazyvimConfig}/lua/config/* $out/lua/config/
  '';
in
{
  home.packages = with pkgs; [
    # Core LazyVim tools
    neovim
    tree-sitter
    lazygit
    ripgrep
    fd

    # Debug tools (needed for DAP)
    lldb  # Debugger
    gdb  # Debugger

    # Clipboard support (needed for LazyVim)
    xclip
    wl-clipboard

    # Language servers and tools
    nodejs_20  # Use Node.js 20 explicitly
    nodePackages.typescript-language-server
    nodePackages.prettier
    nodePackages.eslint
  ];

  xdg.configFile = {
    "nvim" = {
      source = lazyvimMerged;
      recursive = true;
    };
  };
} 