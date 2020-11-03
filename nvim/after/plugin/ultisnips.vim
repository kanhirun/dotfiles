
" ====================================================
" SirVer/ultisnips
" ====================================================

let g:UltiSnipsExpandTrigger       = '<c-l>'
let g:UltiSnipsJumpForwardTrigger  = '<c-b>'
let g:UltiSnipsJumpBackwardTrigger = '<c-z>'

let g:UltiSnipsSnippetsDir = "~/.config/nvim/ultisnips"

command! Snippets call UltiSnips#Edit(<q-bang>, <q-args>)