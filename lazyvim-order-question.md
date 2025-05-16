# LazyVim Plugin Order Warning - Root Cause & Solutions

## The Issue Explained
The warning occurs because of how lazy.nvim builds its plugin spec list:

1. First: Core LazyVim (`lazyvim.plugins`)
2. Second: Extras (`lazyvim.plugins.extras.*`)
3. Last: Custom plugins (via `{ import = "plugins" }`)

**Root Cause**: When we put `lazyvim.plugins.extras.*` imports in files under `lua/plugins/`, they're only loaded when the spec list reaches `{ import = "plugins" }`. This violates the required order because extras should be loaded before our custom plugins.

## Current (Problematic) Setup
```
plugins/
├── 00-lazyvim.lua      # Core LazyVim config
├── 01-extras.lua       # LazyVim extras (THIS IS THE PROBLEM)
├── 02-lsp.lua          # Custom LSP config
└── 03-ui.lua           # Custom UI config
```

## Two Clean Solutions

### Solution A: Use LazyExtras Command
```vim
:LazyExtras dap.core lang.python lang.rust lang.typescript lsp.none-ls
```
- Quickest solution
- Good for experimentation
- Not tracked in Git

### Solution B: Restructure Plugin Specs
Move everything to a single entry point (e.g., `lua/config/lazy.lua` or keep `plugins/00-lazyvim.lua`):

```lua
return {
  -- 1. Core LazyVim
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },

  -- 2. All extras here
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },

  -- 3. Finally, pull in custom plugins
  { import = "plugins" },
}
```

Then keep only regular plugin specs (no imports) in:
- `plugins/02-lsp.lua`
- `plugins/03-ui.lua`
etc.

## Quick Checklist
- ❌ Don't put `import = "lazyvim.plugins.extras.*"` in files under `lua/plugins/`
- ✅ Ensure exactly one spec list imports plugins (usually at the end)
- ✅ Use `:LazyExtras` while experimenting

## Question
Would you recommend Solution A or B for a configuration that should be tracked in Git and shared across machines? Are there any gotchas to be aware of with either approach? 