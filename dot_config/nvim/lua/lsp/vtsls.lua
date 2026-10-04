-- ref: https://github.com/vuejs/language-tools/wiki/Neovim
-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
local vtsls_command = 'vtsls'
local vue_command = 'vue-language-server'
local vue_language_server_path = os.getenv('VUE_LANGUAGE_SERVER_PATH')

local has_vtsls = vim.fn.executable(vtsls_command) == 1
local has_vue = vim.fn.executable(vue_command) == 1
  and type(vue_language_server_path) == 'string'
  and vim.uv.fs_stat(vue_language_server_path) ~= nil

if not has_vtsls then
  return {}
end

local tsserver_filetypes = {
  'typescript',
  'javascript',
  'javascriptreact',
  'typescriptreact',
}

if has_vue then
  table.insert(tsserver_filetypes, 'vue')
end

local vtsls_config = {
  cmd = { vtsls_command, '--stdio' },
  settings = {},
  filetypes = tsserver_filetypes,
}

if has_vue then
  vtsls_config.settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          },
        },
      },
    },
  }
end

local configs = {
  vtsls = vtsls_config,
}

if has_vue then
  configs.vue_ls = {
    cmd = { vue_command, '--stdio' },
    filetypes = { 'vue' },
  }
end

return configs
