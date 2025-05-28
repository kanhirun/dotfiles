return {
  "tpope/vim-projectionist",

  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy"
  },

  { 'numToStr/Comment.nvim' },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Test adapters
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      "rouge8/neotest-rust",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
          }),
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = "jest.config.js",
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          }),
          require("neotest-rust"),
        },
      })

      -- Preserve your existing keymaps with neotest equivalents
      vim.keymap.set('n', '<leader>s', function() require("neotest").run.run() end, { silent = true, desc = "Run nearest test" })
      vim.keymap.set('n', '<leader>t', function() require("neotest").run.run(vim.fn.expand("%")) end, { silent = true, desc = "Run file tests" })
      vim.keymap.set('n', '<leader>a', function() require("neotest").run.run(vim.fn.getcwd()) end, { silent = true, desc = "Run all tests" })
      vim.keymap.set('n', '<leader>l', function() require("neotest").run.run_last() end, { silent = true, desc = "Run last test" })
      
      -- Additional neotest keymaps for enhanced functionality
      vim.keymap.set('n', '<leader>to', function() require("neotest").output.open({ enter = true, auto_close = true }) end, { silent = true, desc = "Show test output" })
      vim.keymap.set('n', '<leader>ts', function() require("neotest").summary.toggle() end, { silent = true, desc = "Toggle test summary" })
    end
  },
}