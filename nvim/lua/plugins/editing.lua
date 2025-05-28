return {
  "tpope/vim-projectionist",

  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy"
  },

  { 'numToStr/Comment.nvim' },

  -- test runner
  -- https://github.com/vim-test/vim-test
  {
    "vim-test/vim-test",
    config = function()
      vim.keymap.set('n', '<leader>s', ':TestNearest<CR>', { silent = true, desc = "Run nearest test" })
      vim.keymap.set('n', '<leader>t', ':TestFile<CR>', { silent = true, desc = "Run file tests" })
      vim.keymap.set('n', '<leader>a', ':TestSuite<CR>', { silent = true, desc = "Run all tests" })
      vim.keymap.set('n', '<leader>l', ':TestLast<CR>', { silent = true, desc = "Run last test" })
    end
  },
}
