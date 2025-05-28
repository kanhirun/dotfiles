return {
  -- Neovim file explorer: edit your filesystem like a buffer
  -- https://github.com/stevearc/oil.nvim
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {},
    config = function ()
      require("oil").setup({
        keymaps = {
          ["gp"] = "actions.preview"
        }
      })
    end
  }
}
