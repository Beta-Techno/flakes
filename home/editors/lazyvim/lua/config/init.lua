-- Main LazyVim configuration
-- This file is loaded first and sets up the basic configuration

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core settings
require("config.options")
require("config.keymaps")

-- Load plugin configurations
require("plugins.lazyvim")
require("plugins.lsp")
require("plugins.ui")

-- Plugin imports (must be first)
return {
  -- 1. LazyVim core plugins (must be first)
  { import = "lazyvim.plugins" },

  -- 2. Essential extras only
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },
} 