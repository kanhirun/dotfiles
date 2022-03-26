" Uses the fzf executable installed via brew
set rtp+=/usr/local/opt/fzf

" Invokes FZF easily
" Use --reverse to set cursor at the top of the window
nmap <C-p> :GFiles<CR>

" Jump to buffer quickly
nnoremap <Leader>b :Buffers<CR>

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
<
