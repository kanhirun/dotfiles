return {
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    opts = { keymaps = { visual = false } },
    config = function(_, opts)
      require('nvim-surround').setup(opts)
      local wraps = { ['`'] = '`', ["'"] = "'", ['"'] = '"', ['('] = ')', [')'] = ')', ['['] = ']', [']'] = ']', ['{'] = '}', ['}'] = '}' }
      for key, char in pairs(wraps) do
        vim.keymap.set('x', '<leader>' .. key, '<Plug>(nvim-surround-visual)' .. char, { remap = true, desc = 'Surround with ' .. char })
      end
    end,
  },

  { 'numToStr/Comment.nvim' },
}
