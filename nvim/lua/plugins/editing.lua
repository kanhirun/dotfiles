return {
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    opts = { keymaps = { visual = false } },
    config = function(_, opts)
      local surround = require('nvim-surround')
      surround.setup(opts)
      local wraps = { ['`'] = '`', ["'"] = "'", ['"'] = '"', ['('] = ')', [')'] = ')', ['['] = ']', [']'] = ']', ['{'] = '}', ['}'] = '}' }
      for key, char in pairs(wraps) do
        vim.keymap.set('x', '<leader>' .. key, '<Plug>(nvim-surround-visual)' .. char, { remap = true, desc = 'Surround with ' .. char })
        vim.keymap.set('n', '<leader>' .. key, function()
          local keys = surround.normal_surround({ line_mode = false })
          require('nvim-surround.cache').normal.delimiters = require('nvim-surround.config').get_delimiters(char, false)
          return keys
        end, { expr = true, desc = 'Surround a motion with ' .. char })
      end
    end,
  },

  { 'numToStr/Comment.nvim' },
}
