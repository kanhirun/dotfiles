return {
  "tpope/vim-projectionist",

  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy"
  },

  { 'numToStr/Comment.nvim' },

  {
    "janko-m/vim-test",
    config = function()
      vim.keymap.set('n', '<leader>s', ':TestNearest<CR>', { silent = true })
      vim.keymap.set('n', '<leader>t', ':TestFile<CR>', { silent = true })
      vim.keymap.set('n', '<leader>a', ':TestSuite<CR>', { silent = true })
      vim.keymap.set('n', '<leader>l', ':TestLast<CR>', { silent = true })
    end
  },
}