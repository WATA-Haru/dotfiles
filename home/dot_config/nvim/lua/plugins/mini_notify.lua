local deps = require('plugins.deps')

deps.now(function()
  require('mini.notify').setup()

  vim.notify = require('mini.notify').make_notify({})

  vim.api.nvim_create_user_command('NotifyHistory', function()
    MiniNotify.show_history()
  end, { desc = 'Show notify history' })
end)
