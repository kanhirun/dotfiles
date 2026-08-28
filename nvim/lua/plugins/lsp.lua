return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)

        -- ===========
        -- Keymaps
        -- ==========

        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('g]', vim.diagnostic.goto_next, '[G]oto Next Error')
        map('g[', vim.diagnostic.goto_prev, '[G]oto Previous Error')

        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>k', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
        -- Skip the menu: apply the fix for the diagnostic under the cursor when
        -- the server offers exactly one. Falls back to a picker if there are several.
        map('<leader>K', function()
          vim.lsp.buf.code_action { apply = true, context = { only = { 'quickfix' } } }
        end, 'Quick [F]ix Diagnostic')
        -- Whole-buffer fix: ask the server for every auto-fixable problem at once,
        -- no cursor positioning required. Needs server-side `source.fixAll` support.
        map('<leader>F', function()
          vim.lsp.buf.code_action {
            apply = true,
            context = { only = { 'source.fixAll' }, diagnostics = {} },
          }
        end, '[F]ix All in Buffer')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gi', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('<leader>gs', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>gS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>gt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

        local function client_supports_method(client, method, bufnr)
          if vim.fn.has 'nvim-0.11' == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Diagnostic Config
    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {}
    }

    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- NOTE: mason-lspconfig v2 dropped `handlers`/`setup_handlers`. Servers are now
    -- configured with `vim.lsp.config()` and started with `vim.lsp.enable()`; the
    -- tables below are merged on top of nvim-lspconfig's own `lsp/<name>.lua`.
    local servers = {
      pyright = {},
      ts_ls = {
        settings = {
          typescript = {
            preferences = {
              includePackageJsonAutoImports = "auto",
            },
          },
        },
        init_options = {
          preferences = {
            organizeImportsOnFormat = true,
          },
        },
      },
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            -- Telescope's workspace-symbol picker leans on this
            symbolMatcher = 'fuzzy',
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      },
    }

    -- gopls is deliberately not mason-managed: it comes from goenv so it always
    -- matches the active Go toolchain (mason's copy would shadow it on $PATH).
    local ensure_installed = vim.tbl_filter(function(name)
      return name ~= 'gopls'
    end, vim.tbl_keys(servers or {}))
    vim.list_extend(ensure_installed, {
      'stylua',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      -- mason-tool-installer above handles installation
      ensure_installed = {},
      automatic_enable = true,
    }

    -- blink.cmp does not register its capabilities globally, so do it here
    vim.lsp.config('*', { capabilities = capabilities })

    for server, config in pairs(servers) do
      vim.lsp.config(server, config)
    end

    -- Start anything already on $PATH (mason's automatic_enable only covers
    -- servers it installed itself, which misses e.g. a goenv/asdf-managed gopls)
    vim.lsp.enable(vim.tbl_keys(servers))
  end,
}
