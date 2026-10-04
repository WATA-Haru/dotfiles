local deps = require('plugins.deps')

deps.later(function()
  require('mini.move').setup()
end)
