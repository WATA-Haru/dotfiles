local deps = require('plugins.deps')

deps.now(function()
  local starter = require('mini.starter')
  starter.setup({
    items = {
      starter.sections.recent_files(5, false, true),
      starter.sections.sessions(5, true)
    }
  })
end)
