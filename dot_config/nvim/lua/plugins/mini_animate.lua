local deps = require('plugins.deps')

deps.later(function()
  local animate = require('mini.animate')
  animate.setup({
    cursor = {
      -- because Go Definition lsp to be slowly
      enable = false,
    },
    scroll = {
      -- Animate for 150 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
    }
  })

  -- Disable mini.animate during mouse wheel scroll for instant response
  local scroll_without_animate = function(key)
    local old = vim.g.minianimate_disable
    vim.g.minianimate_disable = true -- Global flag to disable mini.animate effects
    vim.cmd('normal! ' .. key)       -- Execute key in normal mode ('!' ignores user mappings)
    vim.schedule(function()          -- Defer restore to next event loop to ensure scroll completes
      vim.g.minianimate_disable = old
    end)
  end

  for _, key in ipairs({ '<ScrollWheelUp>', '<ScrollWheelDown>' }) do
    vim.keymap.set({ 'n', 'i', 'x' }, key, function()
      -- nvim_replace_termcodes: Convert '<ScrollWheelUp>' to internal key representation
      scroll_without_animate(vim.api.nvim_replace_termcodes(key, true, true, true))
    end, { desc = 'Scroll without animation' })
  end
end)
