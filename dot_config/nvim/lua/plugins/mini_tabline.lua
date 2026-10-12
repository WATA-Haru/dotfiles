local deps = require('plugins.deps')

deps.later(function()
  require('mini.tabline').setup()
end)
