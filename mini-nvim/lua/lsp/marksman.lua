-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
local home_dir = os.getenv("HOME")
local markdown_lsp_path = home_dir .. "/.local/share/mise/installs/marksman/latest/marksman"

if vim.fn.executable(markdown_lsp_path) ~= 1 then
  return {}
end

return {
  cmd = { markdown_lsp_path, "server" },
  filetypes = { 'markdown', "markdown.mdx" },
  root_markers = { ".marksman.toml", "markdown.mdx" },
}
