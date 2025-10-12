-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: <DOCS_LINK>
-- Add any additional keymaps here

-- Disable alt-j and alt-k keymaps for moving lines up and down, as they would be triggered by esc-j and esc-k
for _, mode in pairs({ "i", "v", "n" }) do
  vim.keymap.del(mode, "<A-j>")
  vim.keymap.del(mode, "<A-k>")
end
