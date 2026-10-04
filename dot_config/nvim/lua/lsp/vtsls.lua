-- ref: https://github.com/vuejs/language-tools/wiki/Neovim
-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
local vtsls_command = 'vtsls'
local vue_command = 'vue-language-server'

-- The Neovim wrapper sets this to the Nix package directory containing
-- `@vue/typescript-plugin`; vtsls needs the directory, not the executable.
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
  init_options = {
    hostInfo = 'neovim',
  },
  settings = {},
  filetypes = tsserver_filetypes,
}

if has_vue then
  -- Vue Language Tools 3 uses hybrid mode: vtsls handles TypeScript in SFCs,
  -- while vue_ls handles the template, HTML, and CSS portions.
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
    root_markers = { 'package.json', '.git' },
    on_init = function(client)
      local retries = 0

      -- vue_ls asks the TypeScript server through custom tsserver messages.
      -- Forward those requests to vtsls and relay its response back to vue_ls.
      local function forward_to_typescript(_, result, context)
        local ts_client = vim.lsp.get_clients({
          bufnr = context.bufnr,
          name = 'vtsls',
        })[1]

        if not ts_client then
          -- Both clients start independently, so vtsls can attach slightly later.
          if retries <= 10 then
            retries = retries + 1
            vim.defer_fn(function()
              forward_to_typescript(_, result, context)
            end, 100)
          else
            vim.notify(
              'vue_ls could not find the vtsls client.',
              vim.log.levels.ERROR
            )
          end
          return
        end

        local params = unpack(result)
        local id, command, payload = unpack(params)

        ts_client:exec_cmd({
          title = 'vue_request_forward',
          command = 'typescript.tsserverRequest',
          arguments = { command, payload },
        }, { bufnr = context.bufnr }, function(_, response)
          client:notify('tsserver/response', {
            { id, response and response.body },
          })
        end)
      end

      client.handlers['tsserver/request'] = forward_to_typescript
    end,
  }
end

return configs
