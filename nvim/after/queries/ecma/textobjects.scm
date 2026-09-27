; extends

(call_expression
  function: [
    (identifier) @_name
    (member_expression object: (identifier) @_name)
    (call_expression function: (member_expression object: (identifier) @_name))
  ]
  arguments: (arguments
    [
      (arrow_function
        body: (statement_block
          .
          "{"
          _+ @test.inner
          "}"))
      (function_expression
        body: (statement_block
          .
          "{"
          _+ @test.inner
          "}"))
    ]
    .)
  (#any-of? @_name "describe" "context" "it" "test" "suite")) @test.outer
