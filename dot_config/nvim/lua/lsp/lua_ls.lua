local command = 'lua-language-server'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command },
  filetypes = { 'lua' },
  on_init = function(client)
    -- Prefer a project's own LuaLS configuration when it has one.
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
        return
      end
    end

    -- Otherwise teach LuaLS about Neovim's LuaJIT runtime and `vim` modules.
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
