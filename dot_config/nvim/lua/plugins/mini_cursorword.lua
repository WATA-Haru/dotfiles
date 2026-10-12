local deps = require('plugins.deps')

deps.later(function()
  require('mini.cursorword').setup()
end)
