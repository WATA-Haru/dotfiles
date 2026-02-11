-- share clipboard with OS
vim.opt.clipboard:append('unnamedplus,unnamed')

-- use 2-spaces indent
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- scroll offset as 3 lines
vim.opt.scrolloff = 3

-- move the cursor to the previous/next line across the first/last character
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

-- color
vim.opt.background = "light"

local map = vim.api.nvim_set_keymap
vim.g.mapleader = ' '
map('i', 'jk', '<Esc>', { noremap = true })
map('n', 'gb', '<C-t>', { desc = 'go back' })

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
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
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
vim.api.nvim_set_hl(0, 'TodoKeyword', { bg = '', fg = '#e00e10', bold = true })
vim.api.nvim_set_hl(0, 'FixMeKeyword', { bg = '', fg = '#FF6200', bold = true })
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

-- NOTE: set before mini.starter
now(function()
  require('mini.sessions').setup()

  local function is_blank(arg)
    return arg == nil or arg == ''
  end
  local function get_sessions(lead)
    -- ref: https://qiita.com/delphinus/items/2c993527df40c9ebaea7
    return vim
        .iter(vim.fs.dir(MiniSessions.config.directory))
        :map(function(v)
          local name = vim.fn.fnamemodify(v, ':t:r')
          return vim.startswith(name, lead) and name or nil
        end)
        :totable()
  end
  vim.api.nvim_create_user_command('SessionWrite', function(arg)
    local session_name = is_blank(arg.args) and vim.v.this_session or arg.args
    if is_blank(session_name) then
      vim.notify('No session name specified', vim.log.levels.WARN)
      return
    end
    vim.cmd('%argdelete')
    MiniSessions.write(session_name)
  end, { desc = 'Write session', nargs = '?', complete = get_sessions })

  vim.api.nvim_create_user_command('SessionDelete', function(arg)
    MiniSessions.select('delete', { force = arg.bang })
  end, { desc = 'Delete session', bang = true })

  vim.api.nvim_create_user_command('SessionLoad', function()
    MiniSessions.select('read', { verbose = true })
  end, { desc = 'Load session' })

  vim.api.nvim_create_user_command('SessionEscape', function()
    vim.v.this_session = ''
  end, { desc = 'Escape session' })

  vim.api.nvim_create_user_command('SessionReveal', function()
    if is_blank(vim.v.this_session) then
      vim.print('No session')
      return
    end
    vim.print(vim.fn.fnamemodify(vim.v.this_session, ':t:r'))
  end, { desc = 'Reveal session' })
end)

now(function()
  local starter = require('mini.starter')
  starter.setup({
    items = {
      starter.sections.recent_files(5, false, true),
      starter.sections.sessions(5, true)
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
  require('mini.surround').setup({
    mappings = {
      add = 'ys',
      delete = 'ds',
      find = '',
      find_left = '',
      highlight = '',
      replace = 'cs',

      -- Add this only if you don't want to use extended mappings
      suffix_last = '',
      suffix_next = '',
    },
    search_method = 'cover_or_next',
  })

  -- Remap adding surrounding to Visual mode selection
  vim.keymap.del('x', 'ys')
  vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })

  -- Make special mapping for "add surrounding for line"
  vim.keymap.set('n', 'yss', 'ys_', { remap = true })
end)

later(function()
  local function mode_nx(keys)
    return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
  end
  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      -- Leader triggers
      mode_nx('<leader>'),

      -- Built-in completion
      { mode = 'i', keys = '<c-x>' },

      -- `g` key
      mode_nx('g'),

      -- Marks
      mode_nx("'"),
      mode_nx('`'),

      -- Registers
      mode_nx('"'),
      { mode = 'i', keys = '<c-r>' },
      { mode = 'c', keys = '<c-r>' },

      -- Window commands
      { mode = 'n', keys = '<c-w>' },

      -- bracketed commands
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },

      -- `z` key
      mode_nx('z'),

      -- text object
      { mode = 'x', keys = 'i' },
      { mode = 'x', keys = 'a' },
      { mode = 'o', keys = 'i' },
      { mode = 'o', keys = 'a' },

      -- option toggle (mini.basics)
      { mode = 'n', keys = 'm' },
      -- mini.map
      { mode = 'n', keys = 'mm', desc = '+mini.map' },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers({ show_contents = true }),
      clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      clue.gen_clues.z(),
    },
  })
end)

later(function()
  require('mini.tabline').setup()
end)

later(function()
  require('mini.bufremove').setup()

  vim.api.nvim_create_user_command(
    'Bufdelete',
    function()
      MiniBufremove.delete()
    end,
    { desc = 'Remove buffer' }
  )
end)

-- TODO: to be refactor
local home_dir = os.getenv("HOME")

now(function()
  local lua_ex_path = home_dir .. '/.local/share/mise/installs/lua-language-server/3.17.1/bin/lua-language-server'

  vim.diagnostic.config({
    virtual_text = true
  })
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

      vim.keymap.set('n', 'gd', function()
        vim.lsp.buf.definition()
      end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

      vim.keymap.set('n', '<space>i', function()
        local buf = vim.api.nvim_get_current_buf()
        local formatters = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/formatting' })
        if #formatters == 0 then
          vim.notify('No matching language-server (formatting)', vim.log.levels.WARN)
          return
        end
        vim.lsp.buf.format({ bufnr = buf })
      end, { buffer = args.buf, desc = 'Format buffer' })
    end,
  })
  vim.lsp.config('*', {
    root_markers = { '.git' },
  })
  vim.lsp.config('lua_ls', {
    cmd = { lua_ex_path },
    filetypes = { 'lua' },
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
          return
        end
      end
      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          library = vim.list_extend(vim.api.nvim_get_runtime_file('lua', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        }
      })
    end,
    settings = {
      Lua = {
        format = { enable = true },
        diagnostics = {
          unusedLocalExclude = { '_*' }
        }
      },
    }
  })
  vim.lsp.enable('lua_ls')
end)

later(function()
  require('mini.fuzzy').setup()
  require('mini.completion').setup({
    lsp_completion = {
      process_items = MiniFuzzy.process_lsp_items,
    },
  })

  -- improve fallback completion
  vim.opt.complete = { '.', 'w', 'k', 'b', 'u' }
  vim.opt.completeopt:append('fuzzy')

  -- define keycodes
  local keys = {
    cn = vim.keycode('<c-n>'),
    cp = vim.keycode('<c-p>'),
    ct = vim.keycode('<c-t>'),
    cd = vim.keycode('<c-d>'),
    cr = vim.keycode('<cr>'),
    cy = vim.keycode('<c-y>'),
  }

  -- select by <tab>/<s-tab>
  vim.keymap.set('i', '<tab>', function()
    -- popup is visible -> next item
    -- popup is NOT visible -> add indent
    return vim.fn.pumvisible() == 1 and keys.cn or keys.ct
  end, { expr = true, desc = 'Select next item if popup is visible' })
  vim.keymap.set('i', '<s-tab>', function()
    -- popup is visible -> previous item
    -- popup is NOT visible -> remove indent
    return vim.fn.pumvisible() == 1 and keys.cp or keys.cd
  end, { expr = true, desc = 'Select previous item if popup is visible' })

  -- complete by <cr>
  vim.keymap.set('i', '<cr>', function()
    if vim.fn.pumvisible() == 0 then
      -- popup is NOT visible -> insert newline
      return require('mini.pairs').cr() -- 注意2
    end
    local item_selected = vim.fn.complete_info()['selected'] ~= -1
    if item_selected then
      -- popup is visible and item is selected -> complete item
      return keys.cy
    end
    -- popup is visible but item is NOT selected -> hide popup and insert newline
    return keys.cy .. keys.cr
  end, { expr = true, desc = 'Complete current item if item is selected' })

  require('mini.snippets').setup({
    mappings = {
      jump_prev = '<c-k>',
    },
  })
end)

later(function()
  require('mini.pick').setup()

  vim.ui.select = MiniPick.ui_select

  -- fuzzy finder
  vim.keymap.set('n', '<space>ff',
    function()
      MiniPick.builtin.files({ tool = 'git' })
    end,
    { desc = 'mini.pick.files' })

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

later(function()
  require('mini.operators').setup({
    replace = { prefix = 'R' },
  })

  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
end)

later(function()
  require('mini.jump').setup({
    delay = {
      idle_stop = 10,
    },
  })
end)

later(function()
  require('mini.jump2d').setup()
end)

later(function()
  local animate = require('mini.animate')
  animate.setup({
    cursor = {
      -- Animate for 100 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 100, unit = 'total' }),
    },
    scroll = {
      -- Animate for 150 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
    }
  })
end)

later(function()
  require('mini.bracketed').setup()
end)

later(function()
  require('mini.splitjoin').setup({
    mappings = {
      toggle = 'gS',
      split = 'ss',
      join = 'sj',
    },
  })
end)

later(function()
  require('mini.move').setup()
end)

later(function()
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
