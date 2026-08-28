return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  --=======================
  -- Configuration
  --=======================

  config = function()
    require('telescope').setup {
      defaults = {
        file_ignore_patterns = { 'node_modules', 'generated' }
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        }
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    --=======================
    -- Keymaps 
    --=======================

    local builtin = require 'telescope.builtin'

    -- TODO: This isn't working as I expected
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition' })

    -- NOTE: <C-p> is so common for file search and frequently used that I will keep
    vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = '[S]earch [F]iles' })

    -- Search directories only; selecting one opens it in oil.nvim.
    -- fd respects .gitignore; the 'find' fallback does not, so it will surface
    -- build output (cdk.out, dist, ...) in repos that gitignore it.
    vim.keymap.set('n', '<C-f>', function()
      local find_command = vim.fn.executable 'fd' == 1
          and { 'fd', '--type', 'd', '--hidden', '--exclude', '.git' }
          or { 'find', '.', '(', '-name', '.git', '-o', '-name', 'node_modules', ')', '-prune', '-o', '-type', 'd', '-print' }

      builtin.find_files {
        prompt_title = 'Directories',
        find_command = find_command,
        attach_mappings = function(prompt_bufnr, _)
          local actions = require 'telescope.actions'
          local action_state = require 'telescope.actions.state'

          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            -- entry.path is already joined against the picker's cwd
            vim.schedule(function()
              require('oil').open(entry.path)
            end)
          end)

          return true
        end,
      }
    end, { desc = '[S]earch Directories' })

    -- vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    -- vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    -- vim.keymap.set('n', '<leader>ss', builtin.lsp_document_symbols, { desc = '[S]earch Document [S]ymbols' })
    vim.keymap.set('n', '<C-l>', builtin.lsp_dynamic_workspace_symbols, { desc = 'Search Workspace Symbols' })
    vim.keymap.set('n', '<C-k>', builtin.lsp_document_symbols, { desc = 'Search Document Symbols' })
    vim.keymap.set('n', '<C-g>', builtin.git_status, { desc = 'Search Git Status' })
    -- vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    -- Fires workspace/diagnostic first so servers can report on files that were
    -- never opened (gopls supports it; ts_ls is push-only and ignores it), then
    -- scopes the results to cwd.
    vim.keymap.set('n', '<leader>sD', function()
      builtin.diagnostics { workspace = true, root_dir = true }
    end, { desc = '[S]earch [D]iagnostics (project-wide)' })
    -- vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    -- Recent files, scoped to cwd, persisted across sessions via shada.
    -- include_current_session defaults to true, so this lists current-session
    -- buffers first (most-recently-used) and then shada history -- i.e. a
    -- superset of :buffers, filtered to the project. Current file is omitted.
    -- Capped at 5: the finder drops any entry whose entry_maker returns nil.
    vim.keymap.set('n', '<leader><leader>', function()
      local gen = require('telescope.make_entry').gen_from_file { cwd = vim.uv.cwd() }
      local n = 0
      builtin.oldfiles {
        cwd_only = true,
        entry_maker = function(line)
          n = n + 1
          if n > 5 then
            return nil
          end
          return gen(line)
        end,
      }
    end, { desc = '[ ] Recent files in cwd (last 5)' })
    vim.keymap.set('n', '<leader>s.', builtin.buffers, { desc = '[S]earch existing buffers' })

    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
