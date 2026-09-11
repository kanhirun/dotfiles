return {
  -- Test runner
  -- https://github.com/vim-test/vim-test
  {
    "vim-test/vim-test",
    config = function()
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
