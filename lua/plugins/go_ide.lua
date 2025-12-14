
return {
  -- LSP server installer
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },

  -- Bridge between Mason + LSP configs
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",  -- provides the default gopls config
      "hrsh7th/cmp-nvim-lsp",   -- lets LSP advertise completion capabilities to cmp
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "gopls" },
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- New Nvim 0.11+ way: config + enable (no require("lspconfig").setup)
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        settings = {
          gopls = {
            usePlaceholders = true,
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
      })

      vim.lsp.enable("gopls") -- activates for Go buffers
    end,
  },

  -- Completion UI (the popup menu)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      vim.o.completeopt = "menu,menuone,noselect"

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(), -- force-open completion menu
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" }, -- <- gopls completion comes through here
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        },
      })
    end,
  },
}
