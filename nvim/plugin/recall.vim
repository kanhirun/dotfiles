" recall.vim
"   1. bring (a fact, event, or situation) back into one's mind; remember.

function! Recall(search, cmd, flag)
  " TODO: Use inputsave(), instead of b: flag
  " let b:search = input("Recall: ", "", "customlist,RecallCompletion")
  let b:search = a:search
  let b:cmd    = a:cmd
  let b:flag   = a:flag

  if b:search == ''
    let l:list = split(system('fasd -s | tail -10'), '\n')  " save this for triaging
    let l:path = inputlist(l:list)
    echo l:path
    return
  endif

  let l:found  = system("fasd -" . a:flag . " ". b:search)

  if a:flag == 'd'
    exe "NERDTreeClose"
    exe 'cd ' . l:found
  endif

  exe a:cmd . " " . l:found
endfunction

" Jogs the user's memory with 'frecent' files with scores
function! RecallCompletion(arglead, cmdline, cursorpos)
  return ['foo', 'bar', 'baz']
endfunction

function! AddRecallIf()
  let l:curr = expand("%")

  " TODO: Ignore '**/nvim/runtime/doc/*.txt', which come from :h
  if exists(":NERDTree")
    " TODO: Check how nerdtree matches against patterns
    " echo match(g:NERDTreeIgnore, l:curr)
  endif

  silent exe "!fasd -A " . l:curr
endfunction

function! DeleteRecall()
  let curr = expand("%")

  silent exe "!fasd -D " . curr

  " call Recall(b:cmd, b:flag)
endfunction

augroup recall
  autocmd!
  autocmd BufEnter  * call AddRecallIf()
  autocmd BufDelete * call DeleteRecall()
augroup END

command! -nargs=1 R  call Recall(<q-args>, 'edit', 'f')
command! -nargs=1 RV call Recall(<q-args>, 'vsp', 'f')
command! -nargs=1 RS call Recall(<q-args>, 'sp', 'f')
command! -nargs=1 RT call Recall(<q-args>, 'tabe', 'f')
command! -nargs=1 RD call Recall(<q-args>, 'NERDTree', 'd')
" nnoremap <leader><leader> :call DeleteRecall()<CR>
