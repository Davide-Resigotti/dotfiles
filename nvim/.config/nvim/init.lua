-- Entrypoint kept small and modular, following the style of
-- https://github.com/jdhao/nvim-config (as an example).

vim.g.mapleader = " "

-- Speed up Lua module loading (Neovim 0.9+)
pcall(function()
  vim.loader.enable()
end)

require("options")
require("autocmds")
require("mappings")
require("plugin_specs")
require("lsp")
require("diagnostics")
