; extends

(call_expression
  function: [
    (identifier) @_name
    (selector_expression field: (field_identifier) @_name)
  ]
  arguments: (argument_list
    (func_literal
      body: (block
        .
        "{"
        _+ @test.inner
        "}"))
    .)
  (#any-of? @_name
    "Describe" "Context" "When" "It" "Specify"
    "FDescribe" "FContext" "FWhen" "FIt" "FSpecify"
    "PDescribe" "PContext" "PWhen" "PIt" "PSpecify"
    "Run")) @test.outer

(call_expression
  function: [
    (identifier) @_name
    (selector_expression field: (field_identifier) @_name)
  ]
  arguments: (argument_list
    (func_literal
      body: (block
        .
        "{"
        _+ @test.inner
        "}")))
  (#any-of? @_name "DescribeTable" "FDescribeTable" "PDescribeTable")) @test.outer

(function_declaration
  name: (identifier) @_name
  body: (block
    .
    "{"
    _+ @test.inner
    "}")
  (#lua-match? @_name "^Test")) @test.outer

(type_declaration
  (type_spec
    (type_identifier)
    [
      (struct_type)
      (interface_type)
    ])) @type.outer
