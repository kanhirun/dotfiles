
" ====================================================
" tpope/vim-surround
" ====================================================

" Surround a word with punctuation
map  <leader>" ysiW"
vmap <leader>" c"<C-R>"<ESC>
map  <leader>' ysiW'
vmap <leader>' c'<C-R>"'<ESC>
map  <leader>] ysiW[
map  <leader>[ ysiW]
vmap <leader>[ c[<C-R>"]<ESC>
vmap <leader>] c[ <C-R>" ]<ESC>
map  <leader>` ysiW`
vmap <leader>` c`<C-R>"`<ESC>
map  <leader>( ysiW)
map  <leader>) ysiW(
vmap <leader>( c(<C-R>")<ESC>
vmap <leader>) c( <C-R>" )<ESC>
map  <leader>} ysiW{
map  <leader>{ ysiW}
vmap <leader>} c{ <C-R>" }<ESC>
vmap <leader>{ c{<C-R>"}<ESC>
nmap <leader>* ysiW*
vmap <leader>* c*<C-R>"*<ESC>

" Surround a word with #{ruby interpolation}
map  <leader># ysiW#
vmap <leader># c#{<C-R>"}<ESC>
