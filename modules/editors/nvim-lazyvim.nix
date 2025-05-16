{ config, pkgs, lib, lazyvimStarter, lazyvimConfig, ... }:

let
  # Define our extras
  extras = ''
    -- 2 · all extras you want
    { import = \"lazyvim.plugins.extras.coding.yanky\" },
    { import = \"lazyvim.plugins.extras.dap.core\" },
    { import = \"lazyvim.plugins.extras.lang.json\" },
    { import = \"lazyvim.plugins.extras.lang.markdown\" },
    { import = \"lazyvim.plugins.extras.lang.python\" },
    { import = \"lazyvim.plugins.extras.lang.rust\" },
    { import = \"lazyvim.plugins.extras.lang.typescript\" },
    { import = \"lazyvim.plugins.extras.lsp.none-ls\" },
    { import = \"lazyvim.plugins.extras.ui.mini-animate\" },
    { import = \"lazyvim.plugins.extras.util.mini-hipatterns\" },
  '';

  # Create a merged LazyVim configuration
  lazyvimMerged = pkgs.runCommand "lazyvim-merged" { } ''
    mkdir -p $out
    cp -R ${lazyvimStarter}/* $out/
    chmod -R u+w $out  # Make files writable

    # Insert our extras before the plugins import in lazy.lua
    sed -i "/{ import = \"plugins\" }/i ${builtins.replaceStrings ["\n"] ["\\n"] extras}" \
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
