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

" This setting is used to specify which files the NERDTree should ignore. It
" must be a list of regular expressions. 
let NERDTreeIgnore=[]


" Yank a dirnode to copy its path to clipboard
call NERDTreeAddKeyMap({
      \ 'key': 'y',
      \ 'callback': 'NERDTreeYankPathToClipboardHandler',
      \ 'quickhelpText': 'yanks the path to @+',
      \ 'scope': 'Node' })

function! NERDTreeYankPathToClipboardHandler(dirnode)
  let dirpath = a:dirnode.path.str()
  echo 'copied: ' . dirpath
  let @+ = dirpath
endfunction
