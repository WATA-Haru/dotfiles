local deps = require('plugins.deps')

deps.now(function()
  require('mini.files').setup({
    options = {
      use_as_default_explorer = true,
    }
  })

  local map_split = function(buf_id, lhs, direction)
    local rhs = function()
      -- Make new window and set it as target
      local cur_target = MiniFiles.get_explorer_state().target_window
      local new_target = vim.api.nvim_win_call(cur_target, function()
        vim.cmd(direction .. ' split')
        return vim.api.nvim_get_current_win()
      end)

      MiniFiles.set_target_window(new_target)

      -- This intentionally doesn't act on file under cursor in favor of
      -- explicit "go in" action (`l` / `L`). To immediately open file,
      -- add appropriate `MiniFiles.go_in()` call instead of this comment.
    end

    -- Adding `desc` will result into `show_help` entries
    local desc = 'Split ' .. direction
    vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
  end

  vim.api.nvim_create_user_command(
    'Ex',
    function(opts)
      local path = opts.args ~= '' and opts.args or vim.api.nvim_buf_get_name(0)
      MiniFiles.open(path, false)
    end,
    { desc = 'Open file explorer', nargs = "?", complete = "file" }
  )
  vim.api.nvim_create_user_command(
    'Ve',
    function(opts)
      local path = opts.args ~= '' and opts.args or vim.api.nvim_buf_get_name(0)
      vim.cmd('vertical leftabove new')
      MiniFiles.open(path, false)
    end,
    { desc = 'Vertical split and Open file explorer', nargs = "?", complete = "file" }
  )
  vim.api.nvim_create_user_command(
    'Se',
    function(opts)
      local path = opts.args ~= '' and opts.args or vim.api.nvim_buf_get_name(0)
      vim.cmd('leftabove new')
      MiniFiles.open(path, false)
    end,
    { desc = 'Horizontal split and Open file explorer', nargs = "?", complete = "file" }
  )

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id
      -- Tweak keys to your liking
      map_split(buf_id, '<leader>s', 'belowright horizontal')
      map_split(buf_id, '<leader>v', 'belowright vertical')
      map_split(buf_id, '<leader>t', 'tab')
    end,
  })
end)
