; extends

; A call that takes a func literal: Ginkgo's Describe and It, t.Run, and
; anything else built out of a block. Go's own query captures the func_literal
; and its block but not the call, so the name was unreachable -- see
; after/queries/ecma/folds.scm, which does the same for describe and it.
(call_expression
  arguments: (argument_list (func_literal))) @fold
