local deps = require('plugins.deps')

deps.later(function()
  require('mini.trailspace').setup()
  -- require('mini.trailspace').setup()と同じlaterに追加
  vim.api.nvim_create_user_command(
    'Trim',
    function()
      MiniTrailspace.trim()
      MiniTrailspace.trim_last_lines()
    end,
    { desc = 'Trim trailing space and last blank lines' }
  )
end)
