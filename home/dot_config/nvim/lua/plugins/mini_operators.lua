local deps = require('plugins.deps')

deps.later(function()
  require('mini.operators').setup({
    replace = { prefix = 'R' },
  })

  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
end)
