return {
  {
    "LazyVim/LazyVim",          --   the core plugin
    import  = "lazyvim.plugins",--   must be first
    version = false,            --   (optional) track main
    opts    = { colorscheme = "tokyonight" },
  },
} 