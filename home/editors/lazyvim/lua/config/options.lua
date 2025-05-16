-- Editor options
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

--[[
-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Line wrapping
opt.wrap = false
--]]

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor line
opt.cursorline = true

-- Appearance
opt.termguicolors = true
--[[
opt.background = "dark"
--]]
opt.signcolumn = "yes"

--[[
-- Backspace
opt.backspace = "indent,eol,start"
--]]

-- Clipboard
-- opt.clipboard = "unnamedplus"

-- Split windows
opt.splitright = true
opt.splitbelow = true

--[[
-- Consider - as part of keyword
opt.iskeyword:append("-")
--]]

--[[
-- Disable swapfile
opt.swapfile = false
--]]