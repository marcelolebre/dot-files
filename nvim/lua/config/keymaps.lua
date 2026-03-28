-- Keymaps are automatically loaded after lazy.nvim startup
-- Add custom keymaps here; LazyVim defaults live in lazyvim.config.keymaps

local map = vim.keymap.set

-- Quick escape from terminal mode
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })
