require("config.lazy")
require("mycfg")

require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "go", "javascript", "python", "java", "cpp", "asm"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}


--Check error by lsp using gl keys
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic" })

--format on autosave for go
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    vim.lsp.buf.format()
  end,
})

--remap some cntrl commands to space 
vim.keymap.set("n", "<leader>]", vim.lsp.buf.definition, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>t", "<C-t>", { noremap = true, silent = true })

--make it so cursor can freely move around
vim.o.virtualedit = "all"
