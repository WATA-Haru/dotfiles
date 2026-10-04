-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#emmet_ls
local command = 'emmet-language-server'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, '--stdio' },
  filetypes = { "astro", "css", "eruby", "html", "htmlangular", "htmldjango", "javascriptreact", "less", "pug", "sass", "scss", "svelte", "templ", "typescriptreact", "vue" },
  root_markers = { ".git" }
}
