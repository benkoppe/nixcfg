return {
  -- autopairs support
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    -- use opts = {} for passing setup options
  },

  -- use classic view with which-key instead of helix
  {
    "folke/which-key.nvim",
    opts = {
      preset = "classic",
    },
  },

  -- use nixd lsp
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {},
        nil_ls = false,
        lua_ls = {},
      },
    },
  },

  -- use prettierd
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      local supported = {
        "css",
        "graphql",
        "handlebars",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "less",
        "markdown",
        "markdown.mdx",
        "scss",
        "typescript",
        "typescriptreact",
        "vue",
        "yaml",
      }
      for _, ft in ipairs(supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "prettierd")
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = {}
      opts.formatters.prettierd = {}
    end,
  },

  -- changing behavior of cmp scrolling
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")

      opts.mapping = cmp.mapping.preset.insert(vim.tbl_extend("force", opts.mapping, {
        ["<Down>"] = cmp.config.disable,
        ["<Up>"] = cmp.config.disable,
        ["<CR>"] = cmp.config.disable,

        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      }))
      opts.experimental.ghost_text = nil
      -- opts.snippet = {
      --   expand = function(args)
      --     vim.snippet.expand(args.body)
      --   end,
      -- }
    end,
  },

  -- commands for snippets with luasnip
  {
    "L3MON4D3/LuaSnip",
    keys = {
      -- command to expand/jump forward
      {
        "<c-k>",
        function()
          local ls = require("luasnip")
          if ls.expand_or_jumpable() then
            ls.expand_or_jump()
          end
        end,
        silent = true,
        desc = "Expand or jump snippet",
        mode = { "i", "s" },
      },
      -- command to jump backward
      {
        "<c-j>",
        function()
          local ls = require("luasnip")
          if ls.jumpable(-1) then
            ls.jump(-1)
          end
        end,
        silent = true,
        desc = "Jump to prev snippet",
        mode = { "i", "s" },
      },
    },
  },
}
