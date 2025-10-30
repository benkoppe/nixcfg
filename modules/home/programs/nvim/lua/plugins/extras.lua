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

	-- adjust lsps and inlay hints
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				nixd = {},
				nil_ls = false,
				statix = {},
				lua_ls = {},
			},
			inlay_hints = { enabled = false },
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

	-- opencode integration
	{
		"NickvanDyke/opencode.nvim",
		dependencies = {
			-- Recommended for `ask()` and `select()`.
			-- Required for default `toggle()` implementation.
			{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
		},
		config = function()
			---@type opencode.Opts
			vim.g.opencode_opts = {
				-- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
			}

			-- Required for `opts.auto_reload`.
			vim.o.autoread = true

			-- Recommended/example keymaps.
			vim.keymap.set({ "n", "x", "v" }, "<leader>o", "", { desc = "+opencode" })
			vim.keymap.set({ "n", "x" }, "<leader>o?", function()
				require("opencode").ask("@this: ", { submit = true })
			end, { desc = "Ask opencode" })
			vim.keymap.set({ "n", "x" }, "<leader>ox", function()
				require("opencode").select()
			end, { desc = "Execute opencode action…" })
			vim.keymap.set({ "n", "x" }, "<leader>oa", function()
				require("opencode").prompt("@this")
			end, { desc = "Add to opencode" })
			vim.keymap.set("n", "<leader>oo", function()
				require("opencode").toggle()
			end, { desc = "Toggle opencode" })
			vim.keymap.set("n", "<S-C-u>", function()
				require("opencode").command("messages_half_page_up")
			end, { desc = "opencode half page up" })
			vim.keymap.set("n", "<S-C-d>", function()
				require("opencode").command("messages_half_page_down")
			end, { desc = "opencode half page down" })
		end,
	},
}
