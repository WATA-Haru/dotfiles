local deps = require('plugins.deps')

deps.later(function()
  require('mini.pairs').setup()
end)
