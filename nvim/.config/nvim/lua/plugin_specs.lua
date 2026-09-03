-- Plugin manager bootstrap + plugin specs.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Core
	{ "nvim-lua/plenary.nvim", lazy = true },

	-- UI
	{ "folke/which-key.nvim", event = "VeryLazy", opts = {} },
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			input = { enabled = true },
			picker = { enabled = true },
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "auto", -- adapt to vim.opt.background
				background = {
					light = "latte",
					dark = "mocha",
				},
				integrations = {
					lualine = true,
				},
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				lua = { "stylua" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
		opts = {
			options = {
				theme = "auto",
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
			},
		},
	},

	-- Markdown Rendering (in-buffer)
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		ft = { "markdown", "markdown.mdx" },
		opts = {},
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		-- New nvim-treesitter rewrite requires Neovim 0.12+. On Neovim 0.11 we pin to the
		-- locked `master` branch which remains for backward compatibility.
		branch = "master",
		build = ":TSUpdate",
		config = function()
			-- Pinned to the 0.11-compatible `master` branch, which uses `.configs`.
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"python",
					"javascript",
					"typescript",
					"tsx",
					"html",
					"css",
					"json",
					"markdown",
					"markdown_inline",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- LSP + tooling
	{ "neovim/nvim-lspconfig" },
	{ "williamboman/mason.nvim", config = true },
	{ "williamboman/mason-lspconfig.nvim" },

	-- Completion
	-- Keep this eager-loaded so LSP capabilities include completion on first attach.
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer", lazy = true },
	{ "hrsh7th/cmp-path", lazy = true },
	{ "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
	{ "saadparwaiz1/cmp_luasnip" },
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
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
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
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 750 },
					{ name = "path", priority = 500 },
					{ name = "buffer", priority = 250 },
				}),
			})
		end,
	},

	-- Assist / opencode
	{
		"nickjvandyke/opencode.nvim",
		config = function()
			vim.g.opencode_opts = {
				-- Change model to the better 1.5-pro or keep flash
				model = "models/gemini-1.5-flash",
			}

			vim.keymap.set("n", "<leader>oa", function()
				require("opencode").ask()
			end, { desc = "OpenCode Ask" })

			vim.keymap.set("n", "<leader>oe", function()
				require("opencode").edit()
			end, { desc = "OpenCode Edit" })

			vim.o.autoread = true

			-- Fix OpenCode white background
			vim.api.nvim_set_hl(0, "OpenCodeNormal", { bg = "NONE", ctermbg = "NONE" })
			vim.api.nvim_set_hl(0, "OpenCodeBorder", { bg = "NONE", ctermbg = "NONE" })
		end,
	},

	-- Copilot (AI suggestions)
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = "<C-e>",
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			panel = { enabled = false },
		},
	},

	-- Formatting (Prettier)
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				json = { "prettier" },
			},
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 500,
			},
		},
	},

	-- Emmet (High-speed HTML/JSX)
	{
		"olrtg/nvim-emmet",
		config = function()
			vim.keymap.set({ "n", "v" }, "<leader>xe", function()
				require("nvim-emmet").wrap_with_abbreviation()
			end, { desc = "Emmet Wrap" })
		end,
	},
}, {
	ui = { border = "rounded" },

	-- We don't use plugins that require luarocks. Disable this to avoid healthcheck
	-- errors about hererocks/luarocks binaries.
	rocks = { enabled = false },
})
