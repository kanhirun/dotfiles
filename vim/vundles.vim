" ========================================
" Vim plugin configuration
" ========================================
"
" This file contains the list of plugin installed using vundle plugin manager.
" Once you've updated the list of plugin, you can run vundle update by issuing
" the command :BundleInstall from within vim or directly invoking it from the
" command line with the following syntax:
" vim --noplugin -u vim/vundles.vim -N "+set hidden" "+syntax on" +BundleClean! +BundleInstall +qall
" Filetype off is required by vundle
filetype off

set rtp+=~/.vim/bundle/vundle/
set rtp+=~/.vim/vundles/ "Submodules
call vundle#rc()

" let Vundle manage Vundle (required)
Bundle "gmarik/vundle"

" ruby.vim
Bundle "tpope/vim-rails.git"
" Adds Ruby text objects
Bundle "vim-ruby/vim-ruby.git"
"Bundle "ecomba/vim-ruby-refactoring"
"Bundle "tpope/vim-rake.git"
"Bundle "tpope/vim-rvm.git"
"Bundle "keith/rspec.vim"
"Bundle "skwp/vim-iterm-rspec"
"Bundle "skwp/vim-spec-finder"
"Bundle "ck3g/vim-change-hash-syntax"
"Bundle "tpope/vim-bundler"

" language.vundle
"Bundle 'sheerun/vim-polyglot'
"Bundle 'garbas/vim-snipmate.git'
"Bundle 'honza/vim-snippets'
"Bundle 'jtratner/vim-flavored-markdown.git'
"Bundle 'scrooloose/syntastic.git'
"Bundle 'nelstrom/vim-markdown-preview'
"Bundle 'skwp/vim-html-escape'
"Bundle 'mxw/vim-jsx'

" git.vundle
" Improves on git to be more useful in the current context
" For example, Gblame shows the author line-by-line
"              Gbrowse opens the current file (or visual block) in the browser
Bundle "tpope/vim-fugitive"
"Bundle "gregsexton/gitv"
"Bundle "mattn/gist-vim"
"Bundle "tpope/vim-git"

" appearance.vundle
" Visually shows the mark on the screen
Bundle "xsunsmile/showmarks.git"
"Bundle "chrisbra/color_highlight.git"
"Bundle "itchyny/lightline.vim"
"Bundle "jby/tmux.vim.git"
"Bundle "morhetz/gruvbox"
"Bundle "chriskempson/base16-vim"
" Required for Gblame in terminal vim
Bundle "godlygeek/csapprox.git"

" textobjects.vundle
" Create your own text objects
Bundle "kana/vim-textobj-user"
" Adds ruby blocks (do-end) as text objects
Bundle "nelstrom/vim-textobj-rubyblock"
" Adds indent blocks (great for yaml) as text objects
" Do `vai/vii` to select around an indent block
"Bundle "austintaylor/vim-indentobject"
" Adds ruby symbols (i.e. :symbol) as text objects
"Bundle "bootleq/vim-textobj-rubysymbol"
" Add `c` (word) and `C` (WORD) for handling columns/blocks
"Bundle "coderifous/textobj-word-column.vim"
" Add date representations as text objects
" Do `da` (date), `df` (date full) to manipulate date
"Bundle "kana/vim-textobj-datetime"
" Adds `e` for entire document. Do `vae` to visual around entire document
"Bundle "kana/vim-textobj-entire"
" Adds `f` textobj. Do `vaf` to select a function.
"Bundle "kana/vim-textobj-function"
" Adds `_` textobj
"Bundle "lucapette/vim-textobj-underscore"
"Bundle "nathanaelkane/vim-indent-guides"
" Adds javascript functions
"Bundle "thinca/vim-textobj-function-javascript"
" Adds funcargs as an "a" object
" Do vaa/via, caa/cia, daa/dia, etc..
"Bundle "vim-scripts/argtextobj.vim"

" search.vundle
" Improves on CtrlP for faster search
Bundle "rking/ag.vim"
"Bundle "justinmk/vim-sneak"
"Bundle "vim-scripts/IndexedSearch"
"Bundle "nelstrom/vim-visual-star-search"
"Bundle "skwp/greplace.vim"
"Bundle "Lokaltog/vim-easymotion"

" project.vundle
" Fuzzy search files
Bundle "ctrlpvim/ctrlp.vim"
"Bundle "jistr/vim-nerdtree-tabs.git"
"Bundle "scrooloose/nerdtree.git"
"Bundle "xolox/vim-misc"
"Bundle "xolox/vim-session"

" vim-improvements.vundle
" Change surrounding quotes, parens, braces, etc.
Bundle "tpope/vim-surround.git"
"Bundle "briandoll/change-inside-surroundings.vim.git"
" Allows repeat (or dot) command to work with vim-surround
Bundle "tpope/vim-repeat.git"
"Bundle "AndrewRadev/splitjoin.vim"
"Bundle "Raimondi/delimitMate"
"Bundle "Shougo/neocomplete.git"
"Bundle "godlygeek/tabular"
"Bundle "tomtom/tcomment_vim.git"
"Bundle "vim-scripts/camelcasemotion.git"
"Bundle "vim-scripts/matchit.zip.git"
"Bundle "kristijanhusak/vim-multiple-cursors"
"Bundle "Keithbsmiley/investigate.vim"
"Bundle "chrisbra/NrrwRgn"
"Bundle "christoomey/vim-tmux-navigator"
"Bundle "MarcWeber/vim-addon-mw-utils.git"
"Bundle "bogado/file-line.git"
"Bundle "mattn/webapi-vim.git"
"Bundle "sjl/gundo.vim"
"Bundle "skwp/YankRing.vim"
"Bundle "tomtom/tlib_vim.git"
"Bundle "tpope/vim-abolish"
"Bundle "tpope/vim-endwise.git"
"Bundle "tpope/vim-ragtag"
"Bundle "tpope/vim-unimpaired"
"Bundle "vim-scripts/AnsiEsc.vim.git"
"Bundle "vim-scripts/AutoTag.git"
"Bundle "vim-scripts/lastpos.vim"
"Bundle "vim-scripts/sudo.vim"
"Bundle "goldfeld/ctrlr.vim"

"Filetype plugin indent on is required by vundle
filetype plugin indent on
