local ls = require 'luasnip'
local s, i = ls.snippet, ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  s('It', fmt([[
It("{}", func() {{
	{}
}}){}]], { i(1, 'a test title'), i(2), i(0) })),
}
