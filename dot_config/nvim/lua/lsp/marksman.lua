-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
local command = 'marksman'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, 'server' },
  filetypes = { 'markdown', 'markdown.mdx' },
  root_markers = { '.marksman.toml', '.git' },
}
