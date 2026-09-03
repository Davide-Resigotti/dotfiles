local capabilities = vim.lsp.protocol.make_client_capabilities()
do
  local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp_lsp.default_capabilities(capabilities)
  end
end

local default = { capabilities = capabilities }

-- Neovim 0.11+ prefers `vim.lsp.config()` over the legacy `require('lspconfig')[name].setup()`.
-- nvim-lspconfig still provides the default configs; we just register overrides here.
vim.lsp.config("pyright", default)
vim.lsp.config("ruff", default)
vim.lsp.config("ts_ls", default)
vim.lsp.config("html", default)
vim.lsp.config("cssls", default)
vim.lsp.config("jsonls", default)
vim.lsp.config("emmet_language_server", default)
-- marksman advertises `markdown.mdx` by default, but Neovim doesn't ship that
-- filetype. We map .mdx to `markdown` (see options.lua), so only advertise
-- markdown here.
vim.lsp.config("marksman", vim.tbl_deep_extend("force", default, {
  filetypes = { "markdown" },
}))
vim.lsp.config("lua_ls", vim.tbl_deep_extend("force", default, {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
}))

-- mason-lspconfig v2 uses Neovim's native LSP (`vim.lsp.config/enable`).
-- We set up our overrides first, then let mason-lspconfig enable installed servers.
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "pyright",
    "ruff",
    -- TypeScript/JS (correct lspconfig name is ts_ls)
    "ts_ls",
    "html",
    "cssls",
    "jsonls",
    "marksman",
    "emmet_language_server",
  },
})
