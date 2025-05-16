return {

  -- 2 · extras (add/remove as you like, order doesn't matter here)
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },

  -- 3 · your own plugins (everything under lua/plugins/**)
  { import = "plugins" },
} 