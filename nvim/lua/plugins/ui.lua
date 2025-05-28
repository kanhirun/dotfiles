return {
  {
    "projekt0n/github-nvim-theme",
    branch = "main",
    priority = 1000,
    config = function()
      vim.cmd("colorscheme github_dark_high_contrast")
    end,
  },

  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {}
  },
}