" Show the current file relative to the parent dir
nmap <C-\>      :NERDTreeFind<CR>
nmap <C-w><C-\> :NERDTreeToggle<CR>

" Ignores confirmation warning when deleting files
let NERDTreeAutoDeleteBuffer=1

" This setting makes NERDTree use a smaller, more compact menu for adding,
" copying, deleting nodes.
let NERDTreeMinimalMenu=1

" This setting is used to change the size of the NERDTree when it is loaded.
let g:NERDTreeWinSize=45

" This setting is used to specify which files the NERDTree should ignore. It
" must be a list of regular expressions. 
let NERDTreeIgnore=[ 'bundle$', 'node_modules$', '__pycache__$', '\.egg-info$' ]


" Yank a dirnode to copy its path to clipboard (.git/refs/heads/tips/10afea9)
call NERDTreeAddKeyMap({
      \ 'key': 'yy',
      \ 'callback': 'NERDTreeYankPathToClipboardHandler',
      \ 'quickhelpText': 'yanks the path to @+',
      \ 'scope': 'Node' })

function! NERDTreeYankPathToClipboardHandler(dirnode)
  let l:dirpath = a:dirnode.path.str()
  echo 'copied: ' . l:dirpath
  let @+ = dirpath
endfunction
