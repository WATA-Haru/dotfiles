local deps = require('plugins.deps')

local add = deps.add

deps.later(function()
  add({
    source = 'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
    depends = { 'nvim-treesitter/nvim-treesitter' },
  })
  require('ts_context_commentstring').setup({})
end)
