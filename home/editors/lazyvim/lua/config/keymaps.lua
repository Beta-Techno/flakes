-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

--[[
-- Key mappings
local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize with arrows
map("n", "<C-Up>", ":resize -2<CR>", { desc = "Resize window up" })
map("n", "<C-Down>", ":resize +2<CR>", { desc = "Resize window down" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize window left" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize window right" })

-- Move text up and down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

-- Keep cursor in place when joining lines
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- Center cursor when moving up/down
map("n", "<C-d>", "<C-d>zz", { desc = "Move down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Move up and center" })

-- Keep cursor in place when searching
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })

-- Better paste
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Quick save
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- Quick quit
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Clear search highlights
map("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- Delete buffer
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Toggle terminal
map("n", "<leader>tt", ":ToggleTerm<CR>", { desc = "Toggle terminal" })
--]]