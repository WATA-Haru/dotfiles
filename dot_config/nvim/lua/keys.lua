local map = vim.api.nvim_set_keymap
vim.g.mapleader = ' '
map('i', 'jk', '<Esc>', { noremap = true })
map('n', 'gb', '<C-t>', { desc = 'go back' })

-- black hole register "- remap
-- https://blog.atusy.net/2025/08/08/map-minus-to-blackhole-register/
map('n', '-', '"_', { desc = 'black hole register' })
map('x', '-', '"_', { desc = 'black hole register' })

-- https://zenn.dev/kawarimidoll/books/6064bf6f193b51/viewer/6c77c3#lua%E9%96%A2%E6%95%B0%E3%82%92%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B%E4%BE%8B
vim.keymap.set('c', '<c-n>', function()
  return vim.fn.wildmenumode() == 1 and '<c-n>' or '<down>'
end, { expr = true, desc = 'Select next' })
vim.keymap.set('c', '<c-p>', function()
  return vim.fn.wildmenumode() == 1 and '<c-p>' or '<up>'
end, { expr = true, desc = 'Select previous' })

