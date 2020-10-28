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
" let &winwidth=&colorcolumn-1

" TODO: Saves command or keymap into .exrc
" I'm not sure how to do this just yet, but it is very useful
" nnoremap <leader><leader> :vsp .projections.json

" Update config quickly
nmap <leader><leader> :source ~/.vimrc<CR>

" Copy the filename to clipboard, pronounced as 'yank file'
nmap <leader>yf :let @+=expand("%")<CR>

" Make 0 go to the first character rather than the beginning
" of the line. When we're programming, we're almost always
" interested in working with text rather than empty space. If
" you want the traditional beginning of line, use ^
nnoremap 0 ^
nnoremap ^ 0

" Quickly edit special files
command! Vimrc :edit ~/.vim/plugins.vim
command! Exrc :edit .exrc
command! Projections :edit .projections.json
command! Snippets :UltiSnipsEdit<CR>

" ====================================================
" tpope/vim-surround
" ====================================================

" Surround a word with punctuation
map  <leader>" ysiw"
vmap <leader>" c"<C-R>"<ESC>
map  <leader>' ysiw'
vmap <leader>' c'<C-R>"'<ESC>
map  <leader>] ysiw[
map  <leader>[ ysiw]
vmap <leader>[ c[<C-R>"]<ESC>
vmap <leader>] c[ <C-R>" ]<ESC>
map  <leader>` ysiw`
vmap <leader>` c`<C-R>"`<ESC>
map  <leader>( ysiw)
map  <leader>) ysiw(
vmap <leader>( c(<C-R>")<ESC>
vmap <leader>) c( <C-R>" )<ESC>
map  <leader>} ysiw{
map  <leader>{ ysiw}
vmap <leader>} c{ <C-R>" }<ESC>
vmap <leader>{ c{<C-R>"}<ESC>
nmap <leader>* ysiw*
vmap <leader>* c*<C-R>"*<ESC>

" Surround a word with #{ruby interpolation}
map  <leader># ysiw#
vmap <leader># c#{<C-R>"}<ESC>

" ====================================================
" janko-m/vim-test
" ====================================================

" Running tests
nmap <silent> <leader>s :TestNearest<CR>
nmap <silent> <leader>t :TestFile<CR>
nmap <silent> <leader>a :TestSuite<CR>
nmap <silent> <leader>l :TestLast<CR>
" nmap <silent> <leader>o :TestVisit<CR>

" ====================================================
" junegunn/fzf.vim
" ====================================================

" Uses the fzf executable installed via brew
set rtp+=/usr/local/opt/fzf

" Invokes FZF easily
" Use --reverse to set cursor at the top of the window
nmap <C-p> :GFiles<CR>

" Jump to buffer quickly
nnoremap <Leader>b :Buffers<CR>

" ====================================================
" scrooloose/nerdtree
" ====================================================

" Show the current file relative to the parent dir
nmap <C-\>      :NERDTreeToggle<CR>
nmap <C-w><C-\> :NERDTreeFind<CR>

let g:NERDTreeWinSize=50

" ====================================================
" junegunn/vim-easy-align
" ====================================================

" Start interactive EasyAlign in visual mode
" Using `al` is more mneumonic than built-in ga
xmap al <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object
nmap al <Plug>(EasyAlign)

" ====================================================
" SirVer/ultisnips
" ====================================================

let g:UltiSnipsExpandTrigger       = '<c-l>'
let g:UltiSnipsJumpForwardTrigger  = '<c-b>'
let g:UltiSnipsJumpBackwardTrigger = '<c-z>'

" ====================================================
" coc.vim 
" ====================================================

" GoTo code navigation.
nmap <silent><nowait> gd <Plug>(coc-definition)
nnoremap <C-w>gd :call CocAction('jumpDefinition', 'vsplit')<CR>
nnoremap <C-t>gd :call CocAction('jumpDefinition', 'tab')<CR>
nnoremap <C-x>gd :call CocAction('jumpDefinition', 'split')<CR>
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)

" Show all type errors for project
nnoremap <nowait> <leader>d :<C-u>CocList diagnostics<CR>
nnoremap <nowait> <leader>o :<C-u>CocList outline<CR>
nnoremap <nowait> <leader>m :<C-u>CocList -I symbols<CR>
" nnoremap <nowait> <leader>d :<C-u>CocNext<CR>
" nnoremap <nowait> <leader>d :<C-u>CocPrev<CR>

" Shows status info at the bottom of the buffer
" To work with other plugins, `:h coc-status` 
set statusline^=%.40f                                " show filepath, maxlength=50
set statusline+=\ \:\:\                              " seperator
set statusline+=%{coc#status()}                      " show coc status (e.g., errors, if exists)
set statusline+=%{get(b:,'coc_current_function','')} " show current function

" Use `g[` and `g]` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> g[ <Plug>(coc-diagnostic-prev)
nmap <silent> g] <Plug>(coc-diagnostic-next)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" ====================================================
" mhinz/startify
" ====================================================

" Disables the cow ASCII header
let g:startify_custom_header = []
