" Uses the fzf executable installed via brew
set rtp+=/usr/local/opt/fzf

" Invokes FZF easily
" Use --reverse to set cursor at the top of the window
nmap <C-p> :GFiles<CR>

" Jump to buffer quickly
nnoremap <Leader>b :Buffers<CR>
