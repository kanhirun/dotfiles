" GoTo code navigation.
nmap <silent><nowait> gd <Plug>(coc-definition)
nnoremap <C-w>gd :call CocAction('jumpDefinition', 'vsplit')<CR>
nnoremap <C-t>gd :call CocAction('jumpDefinition', 'tab drop')<CR>
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

