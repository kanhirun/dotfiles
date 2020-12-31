" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" ================ General Config ====================

" Removes highlights because it's distracting
set nohlsearch

set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set gcr=a:blinkon0              "Disable cursor blink
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim
set clipboard=unnamed           "Yank and paste it outside of vim
set mouse=a                     "Scroll using a mouse
set number

" More natural way of splitting windows
set splitbelow
set splitright

" This makes vim act like all other editors, buffers can
" exist in the background without being in a window.
" http://items.sjbach.com/319/configuring-vim-right
set hidden

" Turn on syntax highlighting
syntax on
colorscheme monokai

" Change leader to <Space> because the backslash is too far away
" The mapleader has to be set before plugin manager starts loading all
" the plugins.
let mapleader="\<Space>"

" Tells neovim where my python executable is located
" Avoids pyenv shim to stabilize vim plugins
let g:python3_host_prog = '~/.pyenv/versions/3.7.4/bin/python3'

" Enables project-level vimrc, try creating an .exrc file
" https://andrew.stwrt.ca/posts/project-specific-vimrc/
set exrc

" =============== Plugin Initialization ===============

call plug#begin('~/.config/nvim/bundle')

" file search, :FZF
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } | Plug 'junegunn/fzf.vim'

" file navigation, :NERDTreeFind
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-projectionist'

" modifying text (i.e. commenting, indenting, surround)
Plug 'tpope/vim-surround'   | Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary' | Plug 'tpope/vim-repeat'
Plug 'junegunn/vim-easy-align'

" autocomplete
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'SirVer/ultisnips'

" task runners
Plug 'janko-m/vim-test'   " test runner, :TestNearest
Plug 'tpope/vim-dispatch' " job runner,  :Start and :Dispatch

" just for the look and feel
Plug 'tpope/vim-fugitive'       " improves git usage in vim
Plug 'sheerun/vim-polyglot'     " provides syntax highlights for many languages
Plug 'airblade/vim-gitgutter'   " see git changes on signcolumn (+, ~, -)
Plug 'seagoj/last-position.vim' " remembers cursor across vim sessions

Plug 'srydell/vim-skeleton' " uses ultisnips, projectionist for dynamic templates

call plug#end()

" ================ Custom Settings ==================

" Removes highlights
nmap <silent> // :noh<CR>

" Show only 5 autocomplete suggestions at most
set pumheight=5

"When typing a string, your quotes auto complete. Move past the quote
"while still in insert mode by hitting Ctrl-a. Example:
"
" type 'foo<c-a>
"
" the first quote will autoclose so you'll get 'foo' and hitting <c-a> will
" put the cursor right after the quote
imap <C-a> <esc>wa

" Show the line ruler
set colorcolumn=90

" Set the width based on a derived value, &colorcolumn-1
" This way, in vsplit, the natural boundaries act as your line ruler.
let &winwidth=&colorcolumn

" Make 0 go to the first character rather than the beginning
" of the line. When we're programming, we're almost always
" interested in working with text rather than empty space. If
" you want the traditional beginning of line, use ^
nnoremap 0 ^
nnoremap ^ 0

" Quickly edit special files
command! Vimrc   :edit ~/.config/nvim/init.vim
command! Scratch :edit .exrc

" ================ Turn Off Swap Files ==============

set noswapfile
set nobackup
set nowb

" ================ Persistent Undo ==================
" Keep undo history across sessions, by storing in file.
" Only works all the time.
if has('persistent_undo') && !isdirectory(expand('~').'/.vim/backups')
  silent !mkdir ~/.vim/backups > /dev/null 2>&1
  set undodir=~/.vim/backups
  set undofile
endif

" ================ Indentation ======================

set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

filetype 
set updatetime=300

" Give more space for displaying messages
set cmdheight=2

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" for plugins (e.g., coc.vim, gitgutter)
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" =============== Other ============================

" Disables autocmds for project-specific vimrc
set secure
