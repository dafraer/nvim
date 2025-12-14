
-- Return a Lazy.nvim plugin spec table.
return {
  {
    -- Install nvim-lint (it runs external linters and publishes results as vim.diagnostic).
    "mfussenegger/nvim-lint", -- nvim-lint: async lint runner that integrates with vim.diagnostic. :contentReference[oaicite:1]{index=1}

    -- Lazy-load early so autocommands exist when you start editing.
    event = { "BufReadPre", "BufNewFile" },

    -- Plugin configuration runs once after the plugin is loaded.
    config = function()
      -- Import the nvim-lint module.
      local lint = require("lint")

      -- Tell nvim-lint which linters to run for which filetypes.
      -- The built-in linter name for Golangci-lint is "golangcilint". :contentReference[oaicite:2]{index=2}
      lint.linters_by_ft = {
        go = { "golangcilint" }, -- Run golangci-lint for Go buffers.
      }

      -- Create (or reuse) an augroup so you don't duplicate autocmds on reload.
      local group = vim.api.nvim_create_augroup("GoGolangciLintOnSave", { clear = true })

      -- Run linting after a file is written to disk.
      -- nvim-lint’s README explicitly suggests BufWritePost + try_lint(). :contentReference[oaicite:3]{index=3}
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group, -- Put this autocmd into our group.
        callback = function(args)
          -- Only lint Go buffers.
          if vim.bo[args.buf].filetype ~= "go" then
            return -- Not Go → do nothing.
          end

          -- If golangci-lint isn't available, fail quietly (no annoying errors).
          if vim.fn.executable("golangci-lint") ~= 1 then
            return -- You installed it, but Neovim can't see it in PATH.
          end

          -- Run the linters configured for the current buffer’s filetype (here: go → golangcilint).
          lint.try_lint()
        end,
      })

      -- Optional: a manual keymap to lint on demand (handy when debugging config).
      vim.keymap.set("n", "<leader>lg", function()
        lint.try_lint() -- Run lint right now.
      end, { desc = "Go: run golangci-lint (nvim-lint)" })
    end,
  },
}
