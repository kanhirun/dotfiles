return {
  -- Neovim file explorer: edit your filesystem like a buffer
  -- https://github.com/stevearc/oil.nvim
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {}
  },

  {
    "projekt0n/github-nvim-theme",
    branch = "main",
    priority = 1000,
    config = function()
      vim.cmd("colorscheme github_dark_high_contrast")
    end,
  },

}
