{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
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
    chmod -R u+w $out  # Make files writable

    # Insert our extras before the plugins import in lazy.lua
    sed -i "/{ import = \"plugins\" }/i ${builtins.replaceStrings ["\n"] ["\\n"] extras}" \
        $out/lua/config/lazy.lua

    # Set clipboard options in lazy.lua
    sed -i "/vim.g.mapleader = \" \"/a vim.opt.clipboard = \"unnamedplus\"\nvim.opt.clipboard:append(\"unnamed\")\nvim.opt.clipboard:append(\"autoselect\")" \
        $out/lua/config/lazy.lua

    # Remove any existing extras from plugins directory
    rm -f $out/lua/plugins/*extras*.lua

    # Copy our custom plugin files
    cp -R ${lazyvimConfig}/lua/plugins/* $out/lua/plugins/  # Copy our plugin files
    cp -R ${lazyvimConfig}/lua/config/* $out/lua/config/  # Copy only the contents of config/
  '';
in
{
  home.packages = with pkgs; [
    # Core tools
    neovim
    tree-sitter
    ripgrep
    fd
    lazygit

    # Python tools
    ruff  # Python linter
    black  # Python formatter
    mypy  # Python type checker
    python3Packages.pylint  # Python linter

    # Rust tools
    rustc  # Rust compiler
    cargo  # Rust package manager
    rust-analyzer  # Rust LSP

    # TypeScript/JavaScript tools
    nodejs  # Node.js runtime
    nodePackages.typescript  # TypeScript compiler
    nodePackages.typescript-language-server  # TypeScript LSP
    nodePackages.prettier  # Code formatter
    nodePackages.eslint  # JavaScript/TypeScript linter

    # JSON tools
    jq  # JSON processor
    nodePackages.jsonlint  # JSON linter

    # Debug tools
    lldb  # Debugger
    gdb  # Debugger

    # Clipboard support
    xclip
    wl-clipboard
  ];

  xdg.configFile = {
    "nvim" = {
      source = lazyvimMerged;
      recursive = true;
    };
  };
}
