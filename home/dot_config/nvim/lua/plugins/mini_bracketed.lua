local deps = require('plugins.deps')

deps.later(function()
  require('mini.bracketed').setup()
end)
