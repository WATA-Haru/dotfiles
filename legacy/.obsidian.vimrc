imap jk <Esc>
imap <C-[> <Esc>
set clipboard=unnamed
exmap tabnext obcommand workspace:next-tab
nmap <C-l> :tabnext<CR>
exmap tabprev obcommand workspace:previous-tab
nmap <C-h> :tabprev<CR>
exmap wq obcommand workspace:close
exmap q obcommand workspace:close

" window controls
" DEACTIVATE <C-W> <C-f> <C-h> default setting
" ref: https://github.com/esm7/obsidian-vimrc-support/issues/67#issuecomment-1067188577
exmap focusRight obcommand editor:focus-right
nmap <C-w>l :focusRight<CR>

exmap focusLeft obcommand editor:focus-left
nmap <C-w>h :focusLeft<CR>

exmap focusTop obcommand editor:focus-top
nmap <C-w>k :focusTop<CR>

exmap focusBottom obcommand editor:focus-bottom
nmap <C-w>j :focusBottom<CR>

exmap splitVertical obcommand workspace:split-vertical
nmap <C-w>v :splitVertical<CR>

exmap splitHorizontal obcommand workspace:split-horizontal
nmap <C-w>s :splitHorizontal<CR>

