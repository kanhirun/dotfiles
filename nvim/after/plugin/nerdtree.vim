" Show the current file relative to the parent dir
nmap <C-\>      :NERDTreeToggle<CR>
nmap <C-w><C-\> :NERDTreeFind<CR>

" Ignores confirmation warning when deleting files
let NERDTreeAutoDeleteBuffer=1

" This setting makes NERDTree use a smaller, more compact menu for adding,
" copying, deleting nodes.
let NERDTreeMinimalMenu=1

" This setting is used to change the size of the NERDTree when it is loaded.
let g:NERDTreeWinSize=45
