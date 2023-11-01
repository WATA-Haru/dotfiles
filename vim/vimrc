set number
set title
set encoding=utf-8

set tabstop=4
set shiftwidth=4
set softtabstop=4
set hlsearch
" set list listchars=tab:\^\

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

"source ~/.vim/pack/42plug/start/stdheader.vim
let g:user42 = 'hwatahik'
let g:mail42 = 'hwatahik@student.42tokyo.jp'
"let g:NERDTreeLimitedSyntax = 1

