if vim.bool_fn.has('mac') then
  vim.g.clipboard = {
    name = 'mac',
    copy = {
      ['+'] = 'pbcopy',
      ['*'] = 'pbcopy',
    },
    paste = {
      ['+'] = 'pbpaste',
      ['*'] = 'pbpaste',
    },
  }
end

if vim.bool_fn.has('linux') then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }

  -- https://github.com/neovim/neovim/discussions/29350#discussioncomment-10299517
  if vim.env.TMUX ~= nil then
    local copy = { 'tmux', 'load-buffer', '-w', '-' }
    local paste = { 'bash', '-c', 'tmux refresh-client -l && sleep 0.05 && tmux save-buffer -' }
    vim.g.clipboard = {
      name = 'tmux',
      copy = {
        ['+'] = copy,
        ['*'] = copy,
      },
      paste = {
        ['+'] = paste,
        ['*'] = paste,
      },
      cache_enabled = 0,
    }
  end
end
