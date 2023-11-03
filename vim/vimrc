set number
set title
set encoding=utf-8

set tabstop=4
set shiftwidth=4
set softtabstop=4
set hlsearch

set clipboard=unnamed,autoselect
inoremap jk <ESC>
let mapleader = " "
filetype plugin indent on

" need to mv tender.nvim/colors/tender.vim ~/.vim/colors
" If you have vim >=8.0 or Neovim >= 0.1.5
if (has("termguicolors"))
 set termguicolors
endif
" For Neovim 0.1.3 and 0.1.4
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" Theme
syntax enable
colorscheme tender

set history=150

" WSL clipboard
if !empty($WSL_DISTRO_NAME)
    let s:clip = '/mnt/c/Windows/System32/clip.exe'
    if executable(s:clip)
        augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system(s:clip, @0) | endif
        augroup END
    endif
endif

let g:user42 = 'hwatahik'
let g:mail42 = 'hwatahik@student.42tokyo.jp'

" tmux coloar setting
if $TMUX != ""
   let &t_8f = "\<Esc>[38:2:%lu:%lu:%lum"
   let &t_8b = "\<Esc>[48:2:%lu:%lu:%lum"
endif

if &term =~ "screen-256color"
    let &t_ti .= "\e[?2004h"
    let &t_te .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function TermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    noremap <special> <expr> <Esc>[200~ TermPasteBegin("0i")
    inoremap <special> <expr> <Esc>[200~ TermPasteBegin("")
    cnoremap <special> <Esc>[200~ <nop>
    cnoremap <special> <Esc>[201~ <nop>
endif
