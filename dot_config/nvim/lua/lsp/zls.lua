local command = 'zls'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command },
  filetypes = { 'zig', 'zir' },
  root_markers = {
    'zls.json',
    'build.zig',
    'build.zig.zon',
    '.git',
  },
}
