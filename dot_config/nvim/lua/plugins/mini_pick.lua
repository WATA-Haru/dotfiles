local deps = require('plugins.deps')

deps.later(function()
  require('mini.pick').setup()

  vim.ui.select = MiniPick.ui_select

  -- fuzzy finder
  vim.keymap.set('n', '<space>ff',
    function()
      MiniPick.builtin.files({ tool = 'git' })
    end,
    { desc = 'mini.pick.files' })

  -- fuzzy finder
  --vim.keymap.set('n', '<space>fg',
  --  function()
  --    MiniPick.builtin.grep_live({ tool = 'git' })
  --  end,
  --  { desc = 'mini.pick.grep_live' })

  -- buffer
  vim.keymap.set('n', '<space>fb', function()
    local wipeout_cur = function()
      vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
    end
    local buffer_mappings = { wipeout = { char = '<c-d>', func = wipeout_cur } }
    MiniPick.builtin.buffers({ include_current = false }, { mappings = buffer_mappings })
  end, { desc = 'mini.pick.buffers' })

  -- history finder
  require('mini.visits').setup()
  vim.keymap.set('n', '<space>fh', function()
    require('mini.extra').pickers.visit_paths()
  end, { desc = 'mini.extra.visit_paths' })

  -- `:hh` help finder
  vim.keymap.set('c', 'h', function()
    if vim.fn.getcmdtype() .. vim.fn.getcmdline() == ':h' then
      return '<c-u>Pick help<cr>'
    end
    return 'h'
  end, { expr = true, desc = 'mini.pick.help' })
end)
