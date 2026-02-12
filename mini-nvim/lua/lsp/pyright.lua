local home_dir = os.getenv("HOME")
local pyright_path = home_dir .. "/.local/share/mise/installs/npm-pyright/latest/lib/node_modules/pyright/langserver.index.js"

if vim.fn.executable('node') ~= 1 or not vim.uv.fs_stat(pyright_path) then
  return {}
end

return {
  cmd = { 'node', pyright_path, '--stdio' },
  filetypes = { 'python' },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  }
}
