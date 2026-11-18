set nocompatible
set number
set title
set encoding=utf-8
set tabstop=2
set shiftwidth=2
set softtabstop=2
set history=150
set hlsearch
set wrap
set mouse=a
filetype indent on
set autoindent
set expandtab
set smarttab

syntax off
colorscheme morning

inoremap jk <Esc>
let mapleader = "<Space>"

" netrw
let g:netrw_banner=0
let g:netrw_list_hide=''

if has('clipboard')
  set clipboard=unnamedplus,autoselect
endif

" osc settings
let g:osc52_disable_paste = 1
if !empty($TMUX)
	let g:osc52_force_avail = 1
endif
packadd osc52
set clipmethod+=osc52

" ale
set omnifunc=ale#completion#OmniFunc
set signcolumn=yes
nnoremap K <cmd>ALEHover<CR>
nnoremap <leader>gd <cmd>ALEGoToDefinition<CR>
nnoremap <leader>gr <cmd>ALEFindReferences<CR>
nnoremap <leader>ca <cmd>ALECodeAction<CR>
set completeopt=menuone,noselect

let g:ale_completion_enabled = 1
let g:ale_hover_to_floating_preview = 1

function! s:HoverOrPreview() abort
	let id = get(get(w:, 'preview', {}), 'id', 0)

	if index(popup_list(), id) >= 0
		let buf = winbufnr(id)
		let lines = getbufline(buf, 1, '$')
		let ft = getbufvar(buf, '&filetype')
	
		call popup_close(id)
		unlet! w:preview
		call ale#preview#Show(lines, {'filetype': ft})
	else
		ALEHover
	endif
endfunction

nnoremap <silent> K :call <SID>HoverOrPreview()<CR>
