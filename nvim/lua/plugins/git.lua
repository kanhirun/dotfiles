return {
  -- Git porcelain
  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    -- No lazy trigger, so this spec stays eager and `:Git ...` keeps working
    -- when typed by hand; the mappings below are shorthand, not the only door.
    config = function()
      -- <leader>g is the Git group. The goto family lives on bare g (gd, gr,
      -- gi, gD, gy) where vim already put it, so nothing here has to share.
      -- `:Git`, not `:Git status`. Fugitive only opens the interactive summary
      -- buffer when the argument list is empty; with `status` as an argument it
      -- falls through to the generic pass-through, which dumps plain git output
      -- into a buffer with no filetype and so no highlighting at all.
      vim.keymap.set('n', '<leader>gs', ':Git<CR>', { silent = true, desc = "[g]it [s]tatus" })
      vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { silent = true, desc = "[g]it [b]lame" })
      -- Fugitive pages the log into a buffer whose hashes are navigable with
      -- <CR>, so the graph flags cost nothing and make it readable at a glance.
      vim.keymap.set('n', '<leader>gl', ':Git log --oneline --graph --decorate<CR>', { silent = true, desc = "[g]it [l]og" })
      vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { silent = true, desc = "[g]it [c]ommit" })
      vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', { silent = true, desc = "[g]it [d]iff" })
    end
  },

  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  }
}
