-- LazyVim imports file
-- This file must be loaded first to satisfy LazyVim's import order requirements
return {
  -- 1. LazyVim core plugins (must be first)
  { import = "lazyvim.plugins" },

  -- 2. Essential extras only
  { import = "lazyvim.plugins.extras.ai.copilot" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },
} 