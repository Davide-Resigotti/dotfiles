vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.background = "light"
vim.o.termguicolors = true

-- Indentation
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
-- vim.opt.cindent = true

-- Sensible splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Diagnostics and UI
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Completion UX (nvim-cmp expects these)
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Disable swapfile; keep undo history
vim.opt.swapfile = false
vim.opt.undofile = true

-- Recommended by some plugins for consistent mappings
vim.g.maplocalleader = "\\"

-- Basic filetype/syntax
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- Ensure .mdx buffers get the filetype marksman expects.
vim.filetype.add({
	extension = {
		mdx = "markdown",
	},
})

-- Disable unused providers to clean up health checks
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
