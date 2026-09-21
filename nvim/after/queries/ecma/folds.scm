; extends

; A call that takes a function literal: describe, it, beforeEach, useEffect,
; every other block-taking call. ecma's own query captures the argument list
; but not the call, so the label lands on the `(` and the selection starts
; after the name -- `F` could reach ('a test', () => {...}) but never
; it('a test', () => {...}). Both are labelled now; this one is the whole call.
(call_expression
  arguments: (arguments [(arrow_function) (function_expression)])) @fold
