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

if exists('$ITERM_PROFILE')
  if exists('$TMUX')
    let &t_SI = "\<Esc>[3 q"
    let &t_EI = "\<Esc>[0 q"
  else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
  endif
end

map <C-n> :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let g:NERDTreeNodeDelimiter = "\u00a0"
let NERDTreeShowHidden=1

set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_max_files=0

"Multiple Cursors
let g:multi_cursor_use_default_mapping=0

" Default mapping
let g:multi_cursor_start_word_key      = '<C-l>'
let g:multi_cursor_select_all_word_key = '<A-l>'
let g:multi_cursor_start_key           = 'g<C-l>'
let g:multi_cursor_select_all_key      = 'g<A-l>'
let g:multi_cursor_next_key            = '<C-l>'
let g:multi_cursor_prev_key            = '<C-k>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'

"Copy without line numbers
:se mouse+=a

set linespace=8
set guifont=Range\ Mono\ Light:h13

set laststatus=2

set backspace=indent,eol,start

:set paste
