local deps = require('plugins.deps')

deps.later(function()
  require('mini.indentscope').setup()
end)
