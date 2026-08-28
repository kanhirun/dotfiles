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


    --======================
    -- 1. File system search
    --======================

    vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Search Files' })
    vim.keymap.set('n', '<C-g>', builtin.git_status, { desc = 'Search Files on Git Status' })

    -- Search directories
    -- Using `fd` respects .gitignore vs. `find`
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
    end, { desc = 'Search Directories' })

    vim.keymap.set('n', '<leader><leader>', function()
      local gen = require('telescope.make_entry').gen_from_file { cwd = vim.uv.cwd() }
      local n = 0
      builtin.oldfiles {
        cwd_only = true,
        entry_maker = function(line)
          if line:match '%.git/COMMIT_EDITMSG$' then
            return nil
          end
          n = n + 1
          if n > 5 then
            return nil
          end
          return gen(line)
        end,
      }
    end, { desc = 'Search Recent Files' })

    --======================
    -- 2. Content search
    --======================

    vim.keymap.set('n', '<C-l>', builtin.lsp_dynamic_workspace_symbols, { desc = 'Search Workspace Symbols' })
    vim.keymap.set('n', '<C-k>', builtin.lsp_document_symbols, { desc = 'Search Document Symbols' })

    vim.keymap.set('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition' })

    --======================
    -- 3. Bug fixes
    --======================

    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    -- Fires workspace/diagnostic first so servers can report on files that were
    -- never opened (gopls supports it; ts_ls is push-only and ignores it), then
    -- scopes the results to cwd.
    vim.keymap.set('n', '<leader>sD', function()
      builtin.diagnostics { workspace = true, root_dir = true }
    end, { desc = '[S]earch [D]iagnostics (project-wide)' })

  end,
}
