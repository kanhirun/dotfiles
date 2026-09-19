return {
  -- Test runner
  -- https://github.com/vim-test/vim-test
  {
    "vim-test/vim-test",
    config = function()
      -- vim-test picks the Go runner per buffer: a file importing
      -- github.com/onsi/ginkgo runs under `ginkgo`, anything else under
      -- `go test`. Ginkgo prints a dot per spec by default; -v prints each
      -- spec's full Describe/Context/It path instead, which is the point of
      -- writing them that way.
      vim.g['test#go#ginkgo#options'] = '-v'

      -- vim-test decides a JS/TS file is a test file only if package.json
      -- names the runner -- and it reads package.json from the cwd, never from
      -- the file's own directory. In a repo whose root is not a node package
      -- (a Go module with infra/ and apps/* under it) every *.test.ts is
      -- "Not a test file". Pointing project_root at the nearest package.json
      -- above the buffer also lets jest and vitest coexist in one repo, since
      -- the runner is then resolved per package rather than once globally.
      local js = { js = true, jsx = true, mjs = true, cjs = true,
                   ts = true, tsx = true, mts = true, cts = true }

      vim.g['test#project_root'] = function()
        if not js[vim.fn.expand('%:e')] then
          return vim.fn.fnameescape(vim.fn.getcwd())
        end
        local dir = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h')
        local found = vim.fn.findfile('package.json', dir .. ';')
        if found == '' then
          return vim.fn.fnameescape(vim.fn.getcwd())
        end
        -- vim-test interpolates this straight into :cd, so it must be escaped.
        return vim.fn.fnameescape(vim.fn.fnamemodify(found, ':p:h'))
      end

      -- Grouped under <leader>t rather than four bare leader letters. The old
      -- layout put a complete mapping on <leader>s and <leader>t while
      -- <leader>sd and <leader>th also existed, so both keys had to wait out
      -- timeoutlen (1000ms, unset) before firing. Grouping frees <leader>s,
      -- <leader>a and <leader>l, and <leader>th joins this group cleanly.
      vim.keymap.set('n', '<leader>tn', ':TestNearest<CR>', { silent = true, desc = "Run nearest test" })
      vim.keymap.set('n', '<leader>tf', ':TestFile<CR>', { silent = true, desc = "Run file tests" })
      vim.keymap.set('n', '<leader>ta', ':TestSuite<CR>', { silent = true, desc = "Run all tests" })
      vim.keymap.set('n', '<leader>tl', ':TestLast<CR>', { silent = true, desc = "Run last test" })
    end
  }
}
