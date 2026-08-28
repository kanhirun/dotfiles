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

    -- Files worth resuming: recent files first, uncommitted changes after.
    -- One flat list so an empty prompt keeps that order and typing fuzzy-matches both.
    local RECENT_LIMIT = 5

    -- Git's two-char porcelain code doubles as the source marker; recent files
    -- get blanks in the same column so the paths stay aligned. Deleted paths
    -- never reach here, they fail the fs_stat check below.
    local function status_hl(xy)
      if xy:find '?' then
        return 'TelescopeResultsDiffUntracked'
      elseif xy:find 'A' then
        return 'TelescopeResultsDiffAdd'
      end
      return 'TelescopeResultsDiffChange'
    end

    vim.keymap.set('n', '<C-g>', function()
      local cwd = vim.uv.cwd()
      local results, seen = {}, {}

      -- Returns true when the path was actually added
      local function add(path, tag, hl)
        local abs = vim.fs.normalize(path)
        if seen[abs] or not vim.uv.fs_stat(abs) then
          return false
        end
        seen[abs] = true
        -- gen_from_file joins relative paths against cwd and displays them as-is
        local under_cwd = vim.startswith(abs, cwd .. '/')
        table.insert(results, {
          value = under_cwd and abs:sub(#cwd + 2) or abs,
          tag = tag,
          hl = hl,
        })
        return true
      end

      -- 1. Git status, gathered before anything is added so a recent file that
      -- is also changed keeps its status marker. Porcelain paths are relative
      -- to the repo root, and -z avoids the quoting/escaping the
      -- human-readable format applies.
      local changed, status_of = {}, {}
      local root = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = cwd, text = true }):wait()
      if root.code == 0 then
        local top = vim.trim(root.stdout)
        local status = vim.system({ 'git', 'status', '--porcelain', '-z' }, { cwd = cwd, text = true }):wait()
        local fields = vim.split(status.stdout or '', '\0', { trimempty = true })
        local i = 1
        while i <= #fields do
          local xy, path = fields[i]:sub(1, 2), fields[i]:sub(4)
          i = i + 1
          if xy:match '[RC]' then
            i = i + 1 -- renames/copies put the source in the following field
          end
          if not path:match '/$' then -- untracked dirs are listed as a directory, not a file
            local abs = vim.fs.normalize(top .. '/' .. path)
            table.insert(changed, abs)
            status_of[abs] = xy
          end
        end
      end

      -- 2. Recent files, filtered to the cwd
      local recent = 0
      for _, path in ipairs(vim.v.oldfiles) do
        if recent >= RECENT_LIMIT then
          break
        end
        local abs = vim.fs.normalize(path)
        if not path:match '%.git/COMMIT_EDITMSG$' and vim.startswith(abs, cwd .. '/') then
          local xy = status_of[abs]
          if add(abs, xy or '  ', xy and status_hl(xy) or 'TelescopeResultsComment') then
            recent = recent + 1
          end
        end
      end

      -- 3. The remaining changed files; `add` skips any already listed above.
      for _, abs in ipairs(changed) do
        add(abs, status_of[abs], status_hl(status_of[abs]))
      end

      -- Prefix the marker onto the file entry's own display. Only `display` is
      -- wrapped, so `ordinal` stays the path and the marker never fuzzy-matches.
      local make_file_entry = require('telescope.make_entry').gen_from_file { cwd = cwd }
      local function entry_maker(item)
        local entry = make_file_entry(item.value)
        local file_display = entry.display -- resolved off gen_from_file's shared metatable
        entry.display = function(e)
          local text, highlights = file_display(e)
          local prefix = item.tag .. ' '
          local shifted = { { { 0, #item.tag }, item.hl } }
          for _, hl in ipairs(highlights or {}) do
            table.insert(shifted, { { hl[1][1] + #prefix, hl[1][2] + #prefix }, hl[2] })
          end
          return prefix .. text, shifted
        end
        return entry
      end

      local conf = require('telescope.config').values
      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Recent & Changed',
          finder = require('telescope.finders').new_table {
            results = results,
            entry_maker = entry_maker,
          },
          sorter = conf.file_sorter {},
          previewer = conf.file_previewer {},
        })
        :find()
    end, { desc = 'Search Recent & Changed Files' })

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
              -- Browsing here never changes the cwd, so there is no
              -- DirChanged to hook -- record the jump ourselves.
              require('config.zoxide').add(entry.path)
              require('oil').open(entry.path)
            end)
          end)

          return true
        end,
      }
    end, { desc = 'Search Directories' })

    -- Jump to any directory zoxide knows about (same database as `j` in the
    -- shell) and open it in oil. The picker opens on the full frecency
    -- ranking, so an empty prompt is a reminder of where you actually go;
    -- typing narrows it with telescope's fuzzy matcher rather than zoxide's
    -- own query resolution.
    local function zoxide_entries()
      local out = vim.system({ 'zoxide', 'query', '--list', '--score' }, { text = true }):wait()
      if out.code ~= 0 then
        vim.notify('zoxide query failed: ' .. (out.stderr or ''), vim.log.levels.ERROR)
        return {}, 0
      end

      -- Lines are `<score> <path>`, highest score first.
      local entries, score_width = {}, 0
      for _, line in ipairs(vim.split(out.stdout or '', '\n', { trimempty = true })) do
        local score, dir = line:match '^%s*(%S+)%s+(.*)$'
        if dir then
          score_width = math.max(score_width, #score)
          table.insert(entries, { score = score, dir = dir })
        end
      end
      return entries, score_width
    end

    vim.keymap.set('n', '<C-j>', function()
      local entries, score_width = zoxide_entries()
      if #entries == 0 then
        return vim.notify('zoxide has no directories yet', vim.log.levels.WARN)
      end

      local displayer = require('telescope.pickers.entry_display').create {
        separator = '  ',
        items = { { width = score_width }, { remaining = true } },
      }

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Zoxide',
          finder = require('telescope.finders').new_table {
            results = entries,
            -- Only the path is the ordinal, so the score never fuzzy-matches.
            entry_maker = function(item)
              local shown = vim.fn.fnamemodify(item.dir, ':~')
              return {
                value = item.dir,
                path = item.dir,
                ordinal = shown,
                display = function()
                  return displayer { { item.score, 'TelescopeResultsComment' }, shown }
                end,
              }
            end,
          },
          sorter = require('telescope.config').values.generic_sorter {},
          attach_mappings = function(prompt_bufnr, _)
            local actions = require 'telescope.actions'
            local action_state = require 'telescope.actions.state'

            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if not entry then
                return
              end

              -- The cd is what records the jump: the DirChanged autocmd in
              -- config.autocmds feeds it to zoxide.
              vim.schedule(function()
                vim.cmd.cd(vim.fn.fnameescape(entry.value))
                require('oil').open(entry.value)
              end)
            end)

            return true
          end,
        })
        :find()
    end, { desc = 'Jump to zoxide directory' })

    --======================
    -- 2. Content search
    --======================

    -- Kinds worth jumping to. Telescope lowercases these before comparing, so
    -- they match the LSP kind names; drop the list to get everything back.
    local SYMBOL_KINDS = { 'function', 'method', 'class', 'struct', 'interface' }

    -- Paths git knows about, absolute. nil when cwd isn't a repo, meaning
    -- "don't filter". --others plus --exclude-standard makes the union of
    -- tracked and unignored-untracked files exactly "not ignored".
    local function git_paths()
      local cwd = vim.uv.cwd()
      local root = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = cwd, text = true }):wait()
      if root.code ~= 0 then
        return nil
      end
      local top = vim.trim(root.stdout)
      local ls = vim.system({
        'git', 'ls-files', '--cached', '--others', '--exclude-standard', '--full-name', '-z',
      }, { cwd = cwd, text = true }):wait()
      local paths = {}
      for _, rel in ipairs(vim.split(ls.stdout or '', '\0', { trimempty = true })) do
        paths[vim.fs.normalize(top .. '/' .. rel)] = true
      end
      return { root = top, paths = paths }
    end

    -- Servers index the vendored and generated trees git ignores, so the symbol
    -- list needs the filter the file pickers get for free from rg. Symbols
    -- outside the repo (stdlib, installed deps) aren't gitignored and stay.
    --
    -- The path set is gathered here rather than inside the finder: the dynamic
    -- finder runs in plenary's async context, where a blocking wait isn't safe.
    vim.keymap.set('n', '<C-l>', function()
      local git = git_paths()
      local opts = { symbols = SYMBOL_KINDS }
      local inner = require('telescope.make_entry').gen_from_lsp_symbols(opts)

      -- The dynamic finder skips nil entries, which is the whole filter.
      opts.entry_maker = function(item)
        local entry = inner(item)
        if not entry or not git or not entry.filename then
          return entry
        end
        local abs = vim.fs.normalize(entry.filename)
        if vim.startswith(abs, git.root .. '/') and not git.paths[abs] then
          return nil
        end
        return entry
      end

      builtin.lsp_dynamic_workspace_symbols(opts)
    end, { desc = 'Search Workspace Symbols' })
    -- Document symbols only ever cover the current buffer, so the gitignore
    -- filter has nothing to do here; the kind list still earns its place.
    vim.keymap.set('n', '<C-k>', function()
      builtin.lsp_document_symbols { symbols = SYMBOL_KINDS }
    end, { desc = 'Search Document Symbols' })

    vim.keymap.set('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition' })

    --======================
    -- 3. Bug fixes
    --======================

    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search Diagnostics' })
    -- Fires workspace/diagnostic first so servers can report on files that were
    -- never opened (gopls supports it; ts_ls is push-only and ignores it), then
    -- scopes the results to cwd.
    vim.keymap.set('n', '<leader>sD', function()
      builtin.diagnostics { workspace = true, root_dir = true }
    end, { desc = '[S]earch [D]iagnostics (project-wide)' })

  end,
}
