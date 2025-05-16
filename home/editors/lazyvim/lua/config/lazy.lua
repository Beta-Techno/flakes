return {
  -- 1. Core LazyVim
  {
    "LazyVim/LazyVim",          --   the core plugin
    import  = "lazyvim.plugins",--   must be first
    version = false,            --   (optional) track main
    opts    = { colorscheme = "tokyonight" },
  },

  -- 2. All extras
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },

  -- 3. Finally, pull in custom plugins
  { import = "plugins" },
} 