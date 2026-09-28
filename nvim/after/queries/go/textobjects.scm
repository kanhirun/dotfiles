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
        _+ @test.inner @describe.inner
        "}"))
    .)
  (#any-of? @_name
    "Describe" "Context" "When"
    "FDescribe" "FContext" "FWhen"
    "PDescribe" "PContext" "PWhen")) @test.outer @describe.outer

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
    "It" "Specify" "FIt" "FSpecify" "PIt" "PSpecify" "Run")) @test.outer @it.outer

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
        _+ @test.inner @describe.inner
        "}")))
  (#any-of? @_name "DescribeTable" "FDescribeTable" "PDescribeTable")) @test.outer @describe.outer

(function_declaration
  name: (identifier) @_name
  body: (block
    .
    "{"
    _+ @test.inner
    "}")
  (#lua-match? @_name "^Test")) @test.outer @it.outer

(type_declaration
  (type_spec
    (type_identifier)
    [
      (struct_type)
      (interface_type)
    ])) @type.outer

(type_declaration
  (type_spec
    (type_identifier)
    [
      (struct_type
        (field_declaration_list
          .
          "{"
          _+ @type.inner
          "}"))
      (interface_type
        "{"
        _+ @type.inner
        "}")
    ]))
