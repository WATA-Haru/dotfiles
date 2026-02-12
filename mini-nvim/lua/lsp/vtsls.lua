-- ref:https://github.com/vuejs/language-tools/wiki/Neovim
-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
local home_dir = os.getenv("HOME")
-- vtsls path
local vtsls_path = home_dir .. "/.local/share/mise/installs/npm-vtsls-language-server/latest/lib/node_modules/@vtsls/language-server/bin/vtsls.js"
-- vtsls for vue
local vue_language_server_path = home_dir .. "/.local/share/mise/installs/npm-vue-language-server/latest/lib/node_modules/@vue/language-server"

local has_node = vim.fn.executable('node') == 1
local has_vtsls = vim.uv.fs_stat(vtsls_path) ~= nil
local has_vue = vim.uv.fs_stat(vue_language_server_path) ~= nil

if not (has_node and has_vtsls) then
  return {}
end

local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact' }
if has_vue then
  table.insert(tsserver_filetypes, 'vue')
end

local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
  configNamespace = 'typescript',
}

local vtsls_config = {
  --  or
  -- cmd = { "deno", "run", "--allow-all", "--unstable-detect-cjs", vtsls_path, "--stdio" },
  cmd = { "node", vtsls_path, "--stdio" },
  settings = {
    vtsls = has_vue and {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    } or {},
  },
  filetypes = tsserver_filetypes,
}

--local ts_ls_config = {
--  init_options = {
--    plugins = {
--      vue_plugin,
--    },
--  },
--  filetypes = tsserver_filetypes,
--}

local configs = {
  vtsls = vtsls_config,
}

if has_vue then
  configs.vue_ls = {}
end

return configs
