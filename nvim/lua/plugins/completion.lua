return {
  { 
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      { 
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        config = function()
          local luasnip = require('luasnip')
          
          -- Load your custom snippets from lua/snippets/ directory
          require('luasnip.loaders.from_lua').load({ paths = vim.fn.stdpath('config') .. '/lua/snippets/' })
          
          -- Also load UltiSnips format from snippets/ directory
          require('luasnip.loaders.from_snipmate').load({ paths = vim.fn.stdpath('config') .. '/snippets/' })
          
          -- UltiSnips-style Tab behavior: expand OR jump forward
          vim.keymap.set({'i', 's'}, '<Tab>', function()
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              -- Fallback to regular Tab when no snippet action available
              return '<Tab>'
            end
          end, { desc = 'Expand snippet or jump forward', expr = true, silent = true })
          
          -- S-Tab to jump backward in snippets
          vim.keymap.set({'i', 's'}, '<S-Tab>', function()
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              return '<S-Tab>'
            end
          end, { desc = 'Jump to previous snippet placeholder', expr = true, silent = true })
          
          -- C-y to accept completion (this will be handled by blink.cmp)
        end,
      },
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = {
        preset = 'none', -- We'll define our own keymaps
        ['<C-y>'] = { 'accept' },
        ['<C-n>'] = { 'select_next' },
        ['<C-p>'] = { 'select_prev' },
        ['<C-u>'] = { 'scroll_documentation_up' },
        ['<C-d>'] = { 'scroll_documentation_down' },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
}
