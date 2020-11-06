" Try :UltiSnipsEdit! to view all matching snippets

let g:UltiSnipsExpandTrigger       = '<c-l>'
let g:UltiSnipsJumpForwardTrigger  = '<c-b>'
let g:UltiSnipsJumpBackwardTrigger = '<c-z>'

let g:UltiSnipsSnippetsDir = "~/.config/nvim/ultisnips"

let g:UltiSnipsEditSplit = 'context'

command! Snippets call UltiSnips#Edit(<q-bang>, <q-args>)
