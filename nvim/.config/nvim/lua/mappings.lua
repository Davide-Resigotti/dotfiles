local map = vim.keymap.set

-- Basic quality-of-life
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "No highlight" })

-- Escaping
map("i", "jk", "<ESC>", { desc = "Escape" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Stay in visual mode while indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Snacks Picker (Fuzzy finder replacement)
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find files" })
map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Grep" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })

-- LSP navigation via Snacks Picker
map("n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
map("n", "gr", function() Snacks.picker.lsp_references() end, { desc = "References" })
map("n", "gi", function() Snacks.picker.lsp_implementations() end, { desc = "Implementation" })
map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })

-- Markdown preview using glow (runs in a terminal split)
map("n", "<leader>mp", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return
  end
  -- Open glow in a new vertical split for a better preview experience
  vim.cmd("vsplit | terminal glow -p " .. vim.fn.shellescape(file))
  vim.cmd("startinsert")
end, { desc = "Glow preview" })
