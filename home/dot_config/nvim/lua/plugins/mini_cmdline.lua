local deps = require('plugins.deps')

deps.now(function()
  require('mini.cmdline').setup({})
end)
