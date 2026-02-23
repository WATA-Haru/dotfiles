local deps = require('plugins.deps')

deps.later(function()
  require('mini.jump2d').setup()
end)
