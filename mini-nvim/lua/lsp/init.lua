vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })

vim.diagnostic.config({
  virtual_text = true
})

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('lsp/init.lua', {})

vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method('textDocument/definition') then
      vim.keymap.set('n', 'gd', function()
        vim.lsp.buf.definition()
      end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })
    end

    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<space>i', function()
        vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
      end, { buffer = args.buf, desc = 'Format buffer' })
    end
  end,
})

vim.lsp.config('*', {
  root_markers = { '.git' },
})

local dirname = vim.fn.stdpath('config') .. '/lua/lsp'
local lsp_names = {}
local lsp_name_set = {}

local function is_empty(tbl)
  return type(tbl) ~= 'table' or next(tbl) == nil
end

local function add_lsp(name, cfg)
  if is_empty(cfg) then
    return
  end
  if not lsp_name_set[name] then
    vim.lsp.config(name, cfg)
    table.insert(lsp_names, name)
    lsp_name_set[name] = true
  end
end

for file, ftype in vim.fs.dir(dirname) do
  if ftype == 'file' and vim.endswith(file, '.lua') and file ~= 'init.lua' then
    local lsp_name = file:sub(1, -5)
    local ok, result = pcall(require, 'lsp.' .. lsp_name)
    if ok and type(result) == 'table' then
      if result.cmd or result.filetypes or result.settings or result.root_markers or result.on_init then
        add_lsp(lsp_name, result)
      else
        for name, cfg in pairs(result) do
          add_lsp(name, cfg)
        end
      end
    end
  end
end

if #lsp_names > 0 then
  vim.lsp.enable(lsp_names)
end
