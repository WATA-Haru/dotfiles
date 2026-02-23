local deps = require('plugins.deps')

deps.now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 1
end)
