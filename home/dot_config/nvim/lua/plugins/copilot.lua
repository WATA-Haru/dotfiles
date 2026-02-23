local deps = require('plugins.deps')

local add = deps.add

deps.later(function()
  add('https://github.com/zbirenbaum/copilot.lua')
  require('copilot').setup()
end)
