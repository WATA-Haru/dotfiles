local command = 'lua-language-server'

if vim.fn.executable(lua_ex_path) ~= 1 then
  return {}
end

return {
  cmd = { command },
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
}
