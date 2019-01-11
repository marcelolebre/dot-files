execute pathogen#infect()
syntax on
filetype plugin indent on

" Setting up solarized theme
syntax enable

" Setting solarized to dark mode
set background=dark

" Setting solarized to be transparent, without this the background is grey and
" only the selected row shows up in blue
let g:solarized_termtrans = 1 

" Setting the solarized theme
colorscheme solarized

set tabstop=4       " number of visual spaces per TAB

set softtabstop=4   " number of spaces in tab when editing

set expandtab       " tabs are spaces

set number              " show line numbers

set showcmd             " show command in bottom bar

set cursorline          " highlight current line

set wildmenu            " visual autocomplete for command menu

set showmatch           " highlight matching [{()}]

set incsearch           " search as characters are entered
set hlsearch            " highlight matches

" move vertically by visual line
nnoremap j gj
nnoremap k gk

" $/^ doesn't do anything
nnoremap $ <nop>
nnoremap ^ <nop>

" highlight last inserted text
nnoremap gV `[v`]

" CtrlP
set runtimepath^=~/.vim/bundle/ctrlp.vim
" CtrlP settings
let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 0
let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'

" allows cursor change in tmux mode
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Open NerdTree with ctrl+n
map <C-n> :NERDTreeToggle<CR>

"Copy without line numbers
:se mouse+=a

set linespace=8
set guifont=Range\ Mono\ Light:h13

set laststatus=2

set backspace=indent,eol,start

:set paste