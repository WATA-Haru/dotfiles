local deps = require('plugins.deps')

deps.later(function()
  require('mini.jump').setup({
    delay = {
      idle_stop = 10,
    },
  })
end)
