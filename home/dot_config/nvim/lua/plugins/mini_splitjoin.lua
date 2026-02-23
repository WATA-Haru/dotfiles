local deps = require('plugins.deps')

deps.later(function()
  require('mini.splitjoin').setup({
    mappings = {
      toggle = 'gS',
      split = 'ss',
      join = 'sj',
    },
  })
end)
