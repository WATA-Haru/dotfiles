local deps = require('plugins.deps')

deps.later(function()
  local mini_map = require('mini.map')
  mini_map.setup({
    integrations = {
      mini_map.gen_integration.builtin_search(),
      mini_map.gen_integration.diff(),
      mini_map.gen_integration.diagnostic(),
    },
    symbols = {
      scroll_line = '▶',
    }
  })
  vim.keymap.set('n', 'mmf', MiniMap.toggle_focus, { desc = 'MiniMap.toggle_focus' })
  vim.keymap.set('n', 'mms', MiniMap.toggle_side, { desc = 'MiniMap.toggle_side' })
  vim.keymap.set('n', 'mmt', MiniMap.toggle, { desc = 'MiniMap.toggle' })
end)
