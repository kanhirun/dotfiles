" recall.vim
"   1. bring (a fact, event, or situation) back into one's mind; remember.

function! Recall(search, cmd, flag)
  " TODO: Use inputsave(), instead of b: flag
  let b:search = a:search
  let b:cmd    = a:cmd
  let b:flag   = a:flag

  " Special handling of empty, and '-' 
  if b:search == ''
    let l:list   = split(system('fasd -l | tail -3'), "\n")
    let l:choice = inputlist(l:list)
    let l:file   = l:list[len(l:list) - l:choice]

    if isdirectory(l:file)
      exe 'NERDTree ' . l:file
      return
    endif

    exe a:cmd . " " . l:file
    return
  endif

  let l:found  = system("fasd -" . a:flag . " ". b:search)

  if a:flag == 'd'
    exe "NERDTreeClose"
    exe 'cd ' . l:found
  endif

  exe a:cmd . " " . l:found
endfunction

" Jogs the user's memory with 'frecent' files
function! RecallCompletion(arglead, cmdline, cursorpos)
  if a:arglead == ''
    let l:paths = system('fasd -tlR | head -2')
  elseif
    let l:paths = system('fasd -lfR ' . a:arglead . ' | head -2')
  endif

  return split(l:paths, '\n')
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

command! -nargs=* -complete=customlist,RecallCompletion R call Recall(<q-args>, 'edit', 'f')
command! -nargs=* RV call Recall(<q-args>, 'vsp', 'f')
command! -nargs=* RS call Recall(<q-args>, 'sp', 'f')
command! -nargs=* RT call Recall(<q-args>, 'tabe', 'f')
command! -nargs=* RD call Recall(<q-args>, 'NERDTree', 'd')
" nnoremap <leader><leader> :call DeleteRecall()<CR>
