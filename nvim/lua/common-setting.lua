-- set number
vim.opt.number = true

-- if you want to check each space count, you will use under the command
-- :set tabstop? | set shiftwidth? | set softtabstop? 
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- show terminal title
vim.opt.title = true
vim.opt.encoding = "utf-8"

-- show tab as  ^ charcter
vim.opt.list = false
vim.opt.clipboard = "unnamedplus"

-- windows wsl only settings 
-- but if you write if vim.fn.has("win64") == 1 then , system cant use clipboard.
if vim.env.TMUX then
    vim.g.clipboard = {
        name = 'tmux',
        copy = {
            ["+"] = {'tmux', 'load-buffer', '-w', '-'},
            ["*"] = {'tmux', 'load-buffer', '-w', '-'},
        },
        paste = {
            ["+"] = {'tmux', 'save-buffer', '-'},
            ["*"] = {'tmux', 'save-buffer', '-'},
        },
        cache_enabled = false,
    }
end

-- recognize python3_host_prog to pass checkhealth
vim.g.python3_host_prog = '/usr/bin/python3'
