local deps = require('plugins.deps')

local add = deps.add

deps.later(function()
  add({
    source = 'https://github.com/ibhagwan/fzf-lua',
    depends = { 'nvim-mini/mini.icons' },
  })

  local fzf = require('fzf-lua')
  fzf.setup({})
  vim.keymap.set('n', '<space>fg', function()
    fzf.live_grep()
  end, { desc = 'fzf live_grep' })
end)
