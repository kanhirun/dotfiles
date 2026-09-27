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
          
          vim.keymap.set('s', '<C-n>', function()
            if luasnip.jumpable(1) then
              luasnip.jump(1)
            end
          end, { desc = 'Next snippet placeholder' })
          vim.keymap.set('s', '<C-p>', function()
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { desc = 'Previous snippet placeholder' })

          -- C-y to accept completion (this will be handled by blink.cmp)
        end,
      },
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = {
        preset = 'none', -- We'll define our own keymaps
        ['<C-y>'] = { 'accept' },
        ['<C-n>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'snippet_backward', 'fallback' },
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
          snippets = { score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },
      fuzzy = {
        implementation = 'lua',
        sorts = {
          function(a, b)
            local sa, sb = a.score + (a.score_offset or 0), b.score + (b.score_offset or 0)
            if sa ~= sb then
              return sa > sb
            end
          end,
          'sort_text',
        },
      },
      signature = { enabled = true },
    },
  },
}
