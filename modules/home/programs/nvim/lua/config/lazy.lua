-- you have to set leader before loading lazy
vim.keymap.set("n", " ", "<Nop>", { silent = true, remap = false })
vim.g.mapleader = " "

-- mnw is a global set by mnw
-- so if it's set this config is being ran from nix
if mnw ~= nil then
	local current_file = debug.getinfo(1, "S").source:sub(2)
	local two_dirs_up = vim.fn.fnamemodify(current_file, ":p:h:h:h")
	vim.g.lazyvim_json = two_dirs_up .. "/lazyvim.json"
	require("lazy").setup({
		dev = {
			path = mnw.configDir .. "/pack/mnw/opt",
			-- match all plugins
			patterns = { "" },
			-- fallback to downloading plugins from git
			-- disable this to force only using nix plugins
			fallback = true,
		},

		-- keep rtp/packpath the same
		performance = {
			reset_packpath = false,
			rtp = {
				reset = false,
			},
		},

		install = {
			-- install the missing plugins
			missing = true,
			colorscheme = { "tokyonight", "habamax" },
		},

		spec = {
			-- add LazyVim and import its plugins
			{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
			-- disable mason.nvim while using nix
			-- precompiled binaries do not agree with nixos, and we can just make nix install it for us
			{ "mason-org/mason-lspconfig.nvim", enabled = false },
			{ "mason-org/mason.nvim", enabled = false },
			-- import/override with your plugins
			{ import = "plugins" },
		},
	})
else
	-- otherwise we have to bootstrap lazy ourselves
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		local lazyrepo = "https://github.com/folke/lazy.nvim.git"
		local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
		if vim.v.shell_error ~= 0 then
			vim.api.nvim_echo({
				{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
				{ out, "WarningMsg" },
				{ "\nPress any key to exit..." },
			}, true, {})
			vim.fn.getchar()
			os.exit(1)
		end
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup({
		spec = {
			-- add LazyVim and import its plugins
			{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
			-- import/override with your plugins
			{ import = "plugins" },
		},
		defaults = {
			-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
			-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
			lazy = false,
			-- It's recommended to leavae version=false for now, since a lot of the plugins that support versioning
			-- have outdated releases, which may break your Neovim install.
			version = false, -- always use the latest git commit
			-- version = "*", -- try installing the latest stable version for plugins that support semver
		},
		install = { colorscheme = { "tokyonight", "habamax" } },
		checker = {
			enabled = true, -- check for plugin updates periodically
			notify = false, -- notify on update
		}, -- automatically check for plugin updates
	})
end
