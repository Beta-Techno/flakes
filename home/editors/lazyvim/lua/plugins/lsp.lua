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

  -- Configure null-ls
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.formatting.prettier,
        nls.builtins.formatting.black,
        nls.builtins.formatting.stylua,
        nls.builtins.diagnostics.eslint,
        nls.builtins.diagnostics.flake8,
      })
    end,
  },
} 