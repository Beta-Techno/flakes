-- Disable Mason and anything that feeds it
return {
  { "williamboman/mason.nvim",          enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
} 