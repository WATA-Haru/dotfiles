-- share clipboard with OS
vim.opt.clipboard:append('unnamedplus,unnamed')

-- use 2-spaces indent
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- color
vim.opt.background = "light"

local map = vim.api.nvim_set_keymap
vim.g.mapleader = ' '
map('i', 'jk', '<Esc>', { noremap = true })

local function paste()
  return {
    vim.fn.split(vim.fn.getreg(""), "\n"),
    vim.fn.getregtype(""),
  }
end

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
  local copy = {'tmux', 'load-buffer', '-w', '-'}
  local paste = {'bash', '-c', 'tmux refresh-client -l && sleep 0.05 && tmux save-buffer -'}
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

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
  require('mini.icons').setup()
end)

now(function()
  require('mini.basics').setup()
end)

now(function()
  require('mini.files').setup({
      options = {
          use_as_default_explorer = true,
      }
  })

  local minifiles_toggle = function(...)
    if not MiniFiles.close() then MiniFiles.open(...) end
  end

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
    { desc = 'Open file explorer', nargs = "?" }
  )
  vim.api.nvim_create_user_command(
    'Ve',
    function(opts)
      local path = opts.args ~= '' and opts.args or vim.api.nvim_buf_get_name(0)
      vim.cmd('vertical leftabove new')
      MiniFiles.open(path, false)
    end,
    { desc = 'Vertical split and Open file explorer', nargs = "?" }
  )
  vim.api.nvim_create_user_command(
    'Se',
    function(opts)
      local path = opts.args ~= '' and opts.args or vim.api.nvim_buf_get_name(0)
      vim.cmd('leftabove new')
      MiniFiles.open(path, false)
    end,
    { desc = 'Horizontal split and Open file explorer', nargs = "?" }
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

now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 1
end)

now(function()
  require('mini.misc').setup()

  MiniMisc.setup_restore_cursor()
  vim.api.nvim_create_user_command('Zoom',
    function()
      MiniMisc.zoom(0, {})
    end,
    { desc = 'Zoom current buffer' }
  )
  map('n', 'mz', '<cmd>Zoom<cr>', { desc = 'Zoom current buffer' })
end)

now(function()
  require('mini.notify').setup()

  vim.notify = require('mini.notify').make_notify({})

  vim.api.nvim_create_user_command('NotifyHistory', function()
    MiniNotify.show_history()
  end, { desc = 'Show notify history' })
end)

later(function()
  require('mini.diff').setup({
    view = {
      style = 'sign',
      signs = { add = '+', change = '~', delete = '-' },
    },
  })
end)

later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  -- Prefer Japanese as the help language
  vim.opt.helplang:prepend('ja')
end)

later(function()
  add('https://github.com/zbirenbaum/copilot.lua')
  require('copilot').setup()
end)

-- colorize specific word and color code
vim.api.nvim_set_hl(0, 'TodoKeyword',{ bg = '', fg='#e00e10', bold = true })
vim.api.nvim_set_hl(0, 'FixMeKeyword',{ bg = '', fg='#FF6200', bold = true })
vim.api.nvim_set_hl(0, 'WipKeyword', { bg = '', fg = '#9900dd', bold = true })
vim.api.nvim_set_hl(0, 'HackKeyword', { bg = '#FFC800', fg = '#ffffff', bold = true })
vim.api.nvim_set_hl(0, 'NoteKeyword', { bg = '', fg = '#45B7D1', bold = true })
vim.api.nvim_set_hl(0, 'InfoKeyword', { bg = '', fg = '#40BA8D', bold = true })

later(function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = require('mini.extra').gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'TODO', 'FIXME', 'WIP', 'HACK', 'NOTE', INFO
      todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'TodoKeyword'),
      fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'FixmeKeyword'),
      wip = hi_words({ 'WIP', 'Wip', 'wip' }, 'WipKeyword'),
      hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'HackKeyword'),
      note = hi_words({ 'NOTE', 'Note', 'note' }, 'NoteKeyword'),
      info = hi_words({ 'INFO', 'Info', 'info' }, 'InfoKeyword'),
      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

later(function()
  require('mini.cursorword').setup()
end)

later(function()
  require('mini.indentscope').setup()
end)

later(function()
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

now(function()
  local starter = require('mini.starter')
  starter.setup({
    items = {
      starter.sections.recent_files(5, false, true)
    }
  })
end)

later(function()
  require('mini.pairs').setup()
end)

later(function()
  local gen_ai_spec = require('mini.extra').gen_ai_spec
  require('mini.ai').setup({
    custom_textobjects = {
      B = gen_ai_spec.buffer(),
      D = gen_ai_spec.diagnostic(),
      I = gen_ai_spec.indent(),
      L = gen_ai_spec.line(),
      N = gen_ai_spec.number(),
      J = { { '()%d%d%d%d%-%d%d%-%d%d()', '()%d%d%d%d%/%d%d%/%d%d()' } }
    },
  })
end)

later(function()
  require('mini.surround').setup()
end)
