
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
