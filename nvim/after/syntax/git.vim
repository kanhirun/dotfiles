" Compact `git log --oneline [--graph]` structure.
"
" The runtime syntax/git.vim understands the verbose log format well, but for
" the compact one it matches the abbreviated hash and nothing else -- the graph
" glyphs, the ref decorations and the subject all fall through to Normal. These
" rules cover what it leaves behind.
"
" The chain below deliberately re-matches the hash rather than leaning on the
" runtime's gitHashAbbrev: that rule's match also begins in column 1, and when
" two matches start at the same column Vim hands priority to whichever was
" defined last -- this file. Claiming the whole prefix keeps the two from
" fighting over the line. Lines with no graph glyph never match here, so plain
" `--oneline` output is left to the runtime rule untouched.
"
" Colours are not set here; they are applied as a theme patch in
" lua/plugins/colorscheme.lua so they survive a colorscheme switch.

syn match gitGraphGlyph /^ *[|\/\\_*][|\/\\_* ]*/ nextgroup=gitOnelineHash
syn match gitOnelineHash /\x\{7,\}\>/ contained nextgroup=gitOnelineRefs skipwhite

" (HEAD -> master, origin/master, tag: v1.0)
syn match gitOnelineRefs /([^)]*)/ contained
      \ contains=gitRefLocal,gitRefRemote,gitRefTag,gitRefHead,gitRefArrow,gitRefDelim

" Generic name first, specific kinds after: same column, later definition wins.
syn match gitRefLocal  /[^ ,()]\+/                contained
syn match gitRefRemote /\<[^ ,()\/]\+\/[^ ,()]*/  contained
syn match gitRefTag    /\<tag: [^,)]*/            contained
syn match gitRefHead   /\<HEAD\>/                 contained
syn match gitRefArrow  /->/                       contained
syn match gitRefDelim  /[(),]/                    contained
