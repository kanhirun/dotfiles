return {
  -- Neovim file explorer: edit your filesystem like a buffer
  -- https://github.com/stevearc/oil.nvim
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {},
    config = function ()
      require("oil").setup({
        use_default_keymaps = false,
        keymaps = {
          ["g?"] = { "actions.show_help", mode = "n" },
          ["<CR>"] = "actions.select",
          ["<C-s>"] = { "actions.select", opts = { vertical = true } },
          ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
          ["<C-t>"] = { "actions.select", opts = { tab = true } },
          ["gp"] = "actions.preview",
          ["gc"] = { "actions.close", mode = "n" },
          ["<C-l>"] = "actions.refresh",
          ["-"] = { "actions.parent", mode = "n" },
          ["_"] = { "actions.open_cwd", mode = "n" },
          ["`"] = { "actions.cd", mode = "n" },
          ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
          ["gs"] = { "actions.change_sort", mode = "n" },
          ["gx"] = "actions.open_external",
          ["g."] = { "actions.toggle_hidden", mode = "n" },
          ["g\\"] = { "actions.toggle_trash", mode = "n" },
        }
      })
      vim.keymap.set('n', '-', ':Oil<CR>', { noremap = true, desc = 'Open File Explorer' })
      -- Pairs with bare `-`: the same explorer, opened beside the file instead of
      -- over it. Not a chord -- opening a split is never needed from insert or
      -- terminal mode, which is what the chord tier is reserved for. <C-[> can't
      -- serve here either: it is byte 0x1B, the same byte as <Esc>, so binding it
      -- would rebind Escape itself.
      vim.keymap.set('n', '<leader>-', ':leftabove vsplit | Oil<CR>', { noremap = true, desc = 'Open File Explorer (left split)' })
    end
  }
}
