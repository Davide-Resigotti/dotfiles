local api = vim.api

-- Ghostty (and other terminals) transparency fix.
local function clear_bg()
  for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "NormalFloat" }) do
    api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
  end
end

clear_bg()
api.nvim_create_autocmd("ColorScheme", {
  group = api.nvim_create_augroup("clear_bg", { clear = true }),
  callback = clear_bg,
})

-- Highlight yanks
api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})
