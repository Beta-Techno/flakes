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