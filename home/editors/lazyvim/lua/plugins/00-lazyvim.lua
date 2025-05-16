return {
  {
    -- ① tell Lazy to pull in the core spec list
    "LazyVim/LazyVim",
    import = "lazyvim.plugins",    -- ← THIS is the missing piece
    version = false,               -- track the main branch (optional but handy)

    -- ② any global LazyVim opts you want to override
    opts = {
      colorscheme = "tokyonight",
    },
  },
}