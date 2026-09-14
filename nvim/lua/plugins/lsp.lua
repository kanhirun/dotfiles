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

        -- `x` is the diagnostic, everywhere it appears: ]x/[x move between them,
        -- <leader>sx lists them (telescope.lua), <leader>rx fixes the one under
        -- the cursor. Learn the noun once and the three addresses follow.
        --
        -- Brackets rather than g]/g[: [ and ] are adjacent because previous and
        -- next are adjacent, so the shape carries the direction and the letter
        -- only has to name the list. Neovim 0.11+ also ships ]d/[d as defaults;
        -- those still work, they just aren't the address this config teaches.
        map(']x', vim.diagnostic.goto_next, 'Next Diagnostic')
        map('[x', vim.diagnostic.goto_prev, 'Previous Diagnostic')

        -- <leader>r is Refactor. Every member changes the code rather than
        -- navigating it, which is what keeps it out of the bare `g` namespace.
        -- rn stays where it was -- it is both the existing muscle memory and the
        -- near-universal convention, worth more than a tidier letter.
        map('<leader>rn', vim.lsp.buf.rename, 'Rename')
        map('<leader>ra', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })
        -- Skip the menu: apply the fix for the diagnostic under the cursor when
        -- the server offers exactly one. Falls back to a picker if there are several.
        map('<leader>rx', function()
          vim.lsp.buf.code_action { apply = true, context = { only = { 'quickfix' } } }
        end, 'Fix Diagnostic')
        -- Shift widens scope, as everywhere else: rx fixes the diagnostic under
        -- the cursor, rX asks the server for every auto-fixable problem at once
        -- with no cursor positioning. Needs server-side `source.fixAll` support.
        map('<leader>rX', function()
          vim.lsp.buf.code_action {
            apply = true,
            context = { only = { 'source.fixAll' }, diagnostics = {} },
          }
        end, 'Fix All in Buffer')
        -- Fix imports: drop the unused ones, then organize what is left.
        --
        -- Two requests, not one. `source.organizeImports` is the portable
        -- name, and gopls does the whole job under it (goimports: add missing,
        -- drop unused, sort). typescript-language-server 5.3 does not: its
        -- handler pins that kind to TypeScript's SortAndCombine mode, so it
        -- only sorts, and on a file whose imports are already sorted it
        -- returns no action at all -- "No code actions available" with an
        -- unused import sitting right there. Removal lives under its own
        -- kind, `source.removeUnusedImports` (RemoveUnused mode, TS 4.9+).
        -- So that is asked for first, then organize. Servers ignore kinds
        -- they do not provide, so gopls sees one request that matters and
        -- pyright sees none.
        --
        -- Applied in sequence and synchronously: each kind's edits land before
        -- the next kind is requested, so the second response is computed
        -- against the text the first one produced rather than a stale copy.
        -- pyright offers nothing here; ruff would be needed for Python.
        map('<leader>fi', function()
          local bufnr = vim.api.nvim_get_current_buf()
          local applied = false
          for _, kind in ipairs { 'source.removeUnusedImports', 'source.organizeImports' } do
            local params = {
              textDocument = vim.lsp.util.make_text_document_params(bufnr),
              range = {
                start = { line = 0, character = 0 },
                ['end'] = { line = 0, character = 0 },
              },
              context = { only = { kind }, diagnostics = {} },
            }
            local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, 2000)
            for id, res in pairs(results or {}) do
              local c = vim.lsp.get_client_by_id(id)
              for _, action in ipairs(res.result or {}) do
                if not action.edit and c and action.data then
                  local resolved = c:request_sync('codeAction/resolve', action, 2000, bufnr)
                  action = resolved and resolved.result or action
                end
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(action.edit, c and c.offset_encoding or 'utf-16')
                  applied = true
                end
              end
            end
          end
          if not applied then
            vim.notify('Imports already clean', vim.log.levels.INFO)
          end
        end, 'Fix Imports')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gi', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        -- Document and workspace symbols live at <leader>ss / <leader>sS in
        -- telescope.lua, the workspace one with a <C-s> chord. They used to be
        -- bound here too, calling the same builtins with no options -- so the
        -- same key family returned filtered or unfiltered results depending on
        -- which address you happened to use.
        -- Type definition joins gd/gr/gi/gD on bare g rather than sitting alone
        -- under <leader>g, which is now the Git group (git.lua). gt is vim's
        -- next-tab, so this takes gy -- the usual address for it.
        map('gy', require('telescope.builtin').lsp_type_definitions, '[G]oto T[y]pe Definition')

        local function client_supports_method(client, method, bufnr)
          if vim.fn.has 'nvim-0.11' == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- Organize imports on save, for servers that advertise they can.
        --
        -- Only servers listing `source.organizeImports` in codeActionKinds get
        -- this, rather than an allowlist of names: gopls and ts_ls both
        -- advertise it, pyright and lua_ls don't, and a server that says
        -- nothing gets nothing. Silence beats surprise on every write.
        --
        -- The request is SYNCHRONOUS on purpose. vim.lsp.buf.code_action is
        -- async, so from BufWritePre the write can land before the edit does --
        -- imports then get organized only sometimes, which is worse to debug
        -- than never working at all.
        --
        -- Only `edit` responses are applied. A server answering with a
        -- `command` instead would need executing, which is itself async and
        -- would reintroduce the race; none of the servers here do that for
        -- this action.
        local ca = client and client.server_capabilities.codeActionProvider
        local organizes = false
        for _, kind in ipairs((type(ca) == 'table' and ca.codeActionKinds) or {}) do
          if kind == 'source.organizeImports' then
            organizes = true
            break
          end
        end

        if organizes then
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = event.buf,
            group = vim.api.nvim_create_augroup('lsp-organize-imports-' .. event.buf, { clear = true }),
            desc = 'Organize imports before writing',
            callback = function()
              local params = {
                textDocument = vim.lsp.util.make_text_document_params(event.buf),
                range = {
                  start = { line = 0, character = 0 },
                  ['end'] = { line = 0, character = 0 },
                },
                context = { only = { 'source.organizeImports' }, diagnostics = {} },
              }

              -- Wrapped so a failure never blocks the write itself; a save that
              -- silently does nothing is recoverable, a save that errors out is not.
              local ok, err = pcall(function()
                local results = vim.lsp.buf_request_sync(event.buf, 'textDocument/codeAction', params, 1000)
                for id, res in pairs(results or {}) do
                  for _, action in ipairs(res.result or {}) do
                    if action.edit then
                      local c = vim.lsp.get_client_by_id(id)
                      vim.lsp.util.apply_workspace_edit(action.edit, c and c.offset_encoding or 'utf-16')
                    end
                  end
                end
              end)
              if not ok then
                vim.notify('Organize imports failed: ' .. tostring(err), vim.log.levels.WARN)
              end
            end,
          })
        end

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
