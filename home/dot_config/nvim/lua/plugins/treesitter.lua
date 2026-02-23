local deps = require('plugins.deps')

local add = deps.add

deps.now(function()
  -- https://zenn.dev/kawarimidoll/articles/18ee967072def7
  -- avoid error
  vim.treesitter.start = (function(wrapped)
    return function(bufnr, lang)
      lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')
      pcall(wrapped, bufnr, lang)
    end
  end)(vim.treesitter.start)

  add({
    source = 'https://github.com/nvim-treesitter/nvim-treesitter',
    hooks = {
      post_checkout = function()
        vim.cmd.TSUpdate()
      end
    },
  })
  -- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/doc/nvim-treesitter.txt
  require('nvim-treesitter').setup()
  require('nvim-treesitter').install({ 'lua', 'vim', 'vue', 'typescript', 'tsx' })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'vim' },
    callback = function()
      -- syntax highlighting, provided by Neovim
      vim.treesitter.start()
      -- NOTE: disable indentexpr because It does not work well
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'vue', 'typescript', 'tsx' },
    callback = function()
      vim.treesitter.start()
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end)
