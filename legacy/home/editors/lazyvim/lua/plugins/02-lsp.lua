-- LSP configuration
return {
  -- Configure LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Add your LSP servers here
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
        pyright = {},
        rust_analyzer = {},
        tsserver = {},
      },
    },
  },

  -- Configure formatters and linters
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },  -- Use ruff instead of flake8
        javascript = { "eslint" },
        typescript = { "eslint" },
      },
    },
  },
}