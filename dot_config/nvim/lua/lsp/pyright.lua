local command = 'pyright-langserver'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, '--stdio' },
  filetypes = { 'python' },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'workspace',
        useLibraryCodeForTypes = true,
      },
    },
  },
}
