
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic under cursor" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
