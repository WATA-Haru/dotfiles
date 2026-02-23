local deps = require('plugins.deps')

-- colorize specific word and color code
vim.api.nvim_set_hl(0, 'TodoKeyword', { bg = '', fg = '#e00e10', bold = true })
vim.api.nvim_set_hl(0, 'FixMeKeyword', { bg = '', fg = '#FF6200', bold = true })
vim.api.nvim_set_hl(0, 'WipKeyword', { bg = '', fg = '#9900dd', bold = true })
vim.api.nvim_set_hl(0, 'HackKeyword', { bg = '#FFC800', fg = '#ffffff', bold = true })
vim.api.nvim_set_hl(0, 'NoteKeyword', { bg = '', fg = '#45B7D1', bold = true })
vim.api.nvim_set_hl(0, 'InfoKeyword', { bg = '', fg = '#40BA8D', bold = true })

deps.later(function()
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
