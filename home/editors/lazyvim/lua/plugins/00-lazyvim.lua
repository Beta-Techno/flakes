return {
  -- 1 Override global LazyVim opts
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- 2 Import the core spec list (must appear before any extras)
  { import = "lazyvim.plugins" },
}