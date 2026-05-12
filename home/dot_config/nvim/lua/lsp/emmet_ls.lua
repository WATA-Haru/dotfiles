-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#emmet_ls

local home_dir = os.getenv("HOME")

-- emmet_ls path
local emmet_ls_path = home_dir .. "/.local/share/mise/installs/npm-emmet-ls/0.4.2/bin/emmet-ls"

local has_node = vim.fn.executable('node') == 1
local has_emmet_ls_path = vim.uv.fs_stat(emmet_ls_path) ~= nil

if not (has_node and has_emmet_ls_path) then
  return {}
end

return {
  cmd = { emmet_ls_path, "--stdio"},
  filetypes = { "astro", "css", "eruby", "html", "htmlangular", "htmldjango", "javascriptreact", "less", "pug", "sass", "scss", "svelte", "templ", "typescriptreact", "vue" },
  root_markers = { ".git" }
}
