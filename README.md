# Neovim Go-Focused Setup

This config bootstraps Neovim with lazy.nvim and a small Go-first plugin stack (gopls, gofmt, golangci-lint, Treesitter, completion). It ships a handful of opinionated defaults for navigation, formatting, and bracket/quote handling.

## Requirements
- Neovim 0.11+ (uses the new `vim.lsp.config` / `vim.lsp.enable` APIs)
- Git (for lazy.nvim bootstrap)
- Go toolchain (`go`, `gofmt`, `goimports`, `gopls`); `golangci-lint` optional but recommended

## Install
1. Place this directory at `~/.config/nvim` (back up your old config first).
2. Start `nvim`; lazy.nvim will auto-clone itself and install plugins.
3. Run `:Mason` to ensure `gopls` is installed; run `:MasonLog` if you need troubleshooting.
4. Install external tools in your PATH: `gofmt` (comes with Go), `goimports` (`go install golang.org/x/tools/cmd/goimports@latest`), and `golangci-lint`.

## What you get
- Theme: Catppuccin applied on startup.
- Treesitter: auto-install + highlight for C, Lua, Vimscript, Markdown, Go, JS, Python, Java, C++, ASM, and more.
- LSP: gopls via mason-lspconfig with placeholders, staticcheck, and unused param analysis enabled.
- Completion: nvim-cmp + LuaSnip with `<C-Space>` to trigger, `<CR>` to accept, `<Tab>/<S-Tab>` to navigate or jump snippets.
- Linting: nvim-lint runs `golangci-lint` after saving Go files; `<leader>lg` triggers it manually.
- Formatting: `goimports` then `gofmt` run on save for Go buffers; there is also an LSP `BufWritePre` formatter for `*.go`.
- Navigation: `<leader>e` opens netrw, `<leader>]` jumps to definition, `<leader>t` jumps back in the tag stack, `gl` shows diagnostics, `[d`/`]d` hop prev/next diagnostics.
- Editing defaults: system clipboard by default, tabs = 4 spaces with smart indent, custom bracket/quote auto-pairs with smart backspace, unrestricted cursor movement (`virtualedit=all`).
- Startup greeting: prints a time-of-day greeting in Tatar.

## File map
```
init.lua                        -- entry; loads lazy + mycfg and Treesitter setup
lua/config/lazy.lua             -- lazy.nvim bootstrap and core options
lua/plugins/*.lua               -- plugin specs (theme, Treesitter, gopls stack, golangci-lint)
lua/mycfg/*.lua                 -- personal tweaks: clipboard, tabs, netrw map, auto-pairs, gofmt/goimports on save, diagnostics keys, greeting, etc.
lua/mycfg/goimports_on_save.lua -- dedicated goimports formatter/autocmd
lsp/gopls.lua                   -- alternative gopls config using async root detection
```

## Go workflow tips
- Save any Go buffer to run goimports then gofmt; warnings appear if either tool is missing from PATH.
- Linting happens after save when `golangci-lint` is available; otherwise it silently skips.
- Use completion with `<C-Space>` to see gopls suggestions; placeholders are enabled for struct literals and function args.

## Updating plugins
Use `:Lazy sync` (or `:Lazy update`) to refresh plugins. mason.nvim installs binaries; re-run `:Mason` if you add new tools.
