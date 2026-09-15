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
        -- `%.git/` needs the slash: `.github/` must stay in. It is only
        -- reached now that find_files walks hidden files (see find_files below).
        file_ignore_patterns = { 'node_modules', 'generated', '%.git/' },
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

    -- <leader>f is Find: locate a thing by its name. <leader>s is Search: look
    -- through content and lists. The split is what the argument is made of --
    -- a name you type here, a match found for you there.
    --
    -- Pickers launched from inside the shell or Claude's pane step to an editor
    -- window first and rebalance the panes once a file is picked. Shared with
    -- oil's <C-]> in oil.lua, so both reach from a pane the same way.
    local panes = require('config.panes')

    -- `hidden` walks dotfiles too: `.github/workflows`, `.envrc`, `.zshrc`.
    -- rg still honours .gitignore, so the ignored trees stay out; `.git/`
    -- itself is dropped by file_ignore_patterns above. `post` on
    -- action_set.select runs after the file has landed in the editor window
    -- and is reset when the next picker starts, so it stays scoped to this
    -- one picker (see search_recent_files below for the longer note).
    local function find_files()
      local from_pane = panes.leave_terminal_window()
      builtin.find_files {
        hidden = true,
        attach_mappings = function()
          if from_pane then
            require('telescope.actions.set').select:enhance { post = panes.balance_panes }
          end
          return true
        end,
      }
    end

    -- <C-f> is the file chord: f is the noun's letter, the same one <leader>ff
    -- carries. It replaced <C-p>, which used to open the recent-files picker
    -- and is now unbound outside the completion menu. Every mode, like <C-]>
    -- and <C-Space>, and `t` is the one that matters: it makes the chord
    -- reach from inside the shell and Claude's pane, which otherwise swallow
    -- it (readline forward-char, which Right also does). Both addresses bind
    -- the same function, so <leader>ff steps out of a pane the same way, and
    -- a file picked from inside a pane shares the screen with it. <C-f> is a
    -- legacy control byte (0x06), so it arrives through Zellij with no kitty
    -- keyboard protocol support.
    vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-f>', find_files, { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>ff', find_files, { desc = 'Find Files' })

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

    local function search_recent_files()
      local from_pane = panes.leave_terminal_window()
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
          -- Launched from a pane, a pick splits the screen evenly between the
          -- pane and the editor once the file is open. `post` on
          -- action_set.select covers every way of picking -- Enter, <C-x>,
          -- <C-v>, <C-t> -- and runs after the file has landed in the editor
          -- window. Telescope resets action enhancements when the next picker
          -- starts (clear_all in Picker:find), so this stays scoped to this
          -- one picker rather than leaking into every select everywhere.
          attach_mappings = function()
            if from_pane then
              require('telescope.actions.set').select:enhance { post = panes.balance_panes }
            end
            return true
          end,
        })
        :find()
    end

    -- <C-k> is the recent-files chord. <C-p> used to land here, and <C-g>
    -- before that; <C-f> spent the file slot on find_files and <C-g> went to
    -- grep, so this takes the key document symbols held, which are now
    -- leader-only at <leader>ss. Every mode, like <C-f>, so it reaches from
    -- inside the shell and Claude's pane; there it displaces readline's
    -- kill-line, and in insert mode Vim's digraph entry, neither of which
    -- earns a chord over resuming a file. <C-k> is VT (0x0B), a legacy
    -- control byte that arrives through Zellij with no kitty keyboard
    -- protocol support.
    --
    -- <leader>fo is the leader twin: it names vim's own `:oldfiles` and
    -- alternates hands, where `fr` would be the same index finger twice.
    -- Both addresses bind the same function, so a pick made from inside a
    -- pane shares the screen with it either way.
    vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-k>', search_recent_files, { desc = 'Find Recent & Changed Files' })
    vim.keymap.set('n', '<leader>fo', search_recent_files, { desc = 'Find Recent & Changed Files' })

    -- Search directories only; selecting one opens it in oil.nvim.
    -- fd respects .gitignore; the 'find' fallback does not, so it will surface
    -- build output (cdk.out, dist, ...) in repos that gitignore it.
    local function search_directories()
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
    end

    -- Deliberately no chord. Directories are reached far less often than files,
    -- and the chord tier is a fixed budget -- spending one here means not
    -- spending it on something reached more often. <C-d> stays half-page scroll.
    -- Find, not Search: a directory is located by the name you type, the same
    -- way a file is. Deliberately no chord -- directories are reached far less
    -- often than files, and the chord tier is a fixed budget.
    vim.keymap.set('n', '<leader>fd', search_directories, { desc = 'Find Directories' })

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

    --
    -- Every mode, like <C-f>: `t` is what lets the chord reach from inside the
    -- shell and Claude's pane, and the same step to an editor window keeps the
    -- picked directory from replacing the pane's buffer. <C-j> is a legacy
    -- control byte (0x0A, linefeed), so it arrives through Zellij with no kitty
    -- keyboard protocol support. In the shell it was a second Enter, which
    -- Enter still is; Claude Code does not bind it.
    local function jump_to_zoxide_directory()
      local from_pane = panes.leave_terminal_window()
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
              -- config.autocmds feeds it to zoxide. Launched from a pane, the
              -- oil listing then shares the screen with it, as a picked file
              -- does from <C-f>.
              vim.schedule(function()
                vim.cmd.cd(vim.fn.fnameescape(entry.value))
                require('oil').open(entry.value)
                if from_pane then
                  panes.balance_panes()
                end
              end)
            end)

            return true
          end,
        })
        :find()
    end

    vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-j>', jump_to_zoxide_directory, { desc = 'Jump to zoxide directory' })

    --======================
    -- 2. Content search
    --======================

    -- Live grep over the tree. rg drives it, so .gitignore is honoured and
    -- hidden files are walked the way find_files walks them; `%.git/` is
    -- dropped by file_ignore_patterns above. Same pane handling as the file
    -- pickers: launched from the shell or Claude's pane, the match lands in an
    -- editor window and the panes rebalance once one is picked.
    local function live_grep()
      local from_pane = panes.leave_terminal_window()
      builtin.live_grep {
        additional_args = { '--hidden' },
        attach_mappings = function()
          if from_pane then
            require('telescope.actions.set').select:enhance { post = panes.balance_panes }
          end
          return true
        end,
      }
    end

    -- <C-g> is the grep chord: g for grep. Every mode, like <C-f>, so it
    -- reaches from inside the shell and Claude's pane; there it
    -- displaces readline's abort-line, which <C-c> also does. <C-g> is BEL
    -- (0x07), a legacy control byte that arrives through Zellij with no
    -- kitty keyboard protocol support. Normal mode's default <C-g> only
    -- prints the file name, which the statusline already shows.
    --
    -- <leader>fg is the leader twin. By the Find/Search split above it would
    -- read as <leader>sg, since grep is a content search; `fg` is the address
    -- muscle memory already carries from the usual telescope setups.
    vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-g>', live_grep, { desc = 'Live Grep' })
    vim.keymap.set('n', '<leader>fg', live_grep, { desc = 'Live Grep' })

    -- Kinds worth jumping to. Telescope lowercases these before comparing, so
    -- they match the LSP kind names; drop the list to get everything back.
    --
    -- `constant` is what the server calls it, and servers differ on when they
    -- do: gopls and lua_ls report `const` as constant, ts_ls reports a
    -- top-level `const` as variable and keeps constant for enum-like cases.
    -- `variable` is left out on purpose, since it would bring every `let` in.
    local SYMBOL_KINDS = { 'function', 'method', 'class', 'struct', 'interface', 'constant' }

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
    local function search_workspace_symbols()
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
    end

    -- Document symbols only ever cover the current buffer, so the gitignore
    -- filter has nothing to do here; the kind list still earns its place.
    local function search_document_symbols()
      builtin.lsp_document_symbols { symbols = SYMBOL_KINDS }
    end

    -- One function per scope. lsp.lua used to bind <leader>gs/<leader>gS to
    -- the same builtins with no options at all -- the same capability,
    -- silently unfiltered, at other addresses. Those are deleted; these three
    -- are the only symbol entry points.
    --
    -- Document symbols are leader-only. They had <C-k>, which now opens the
    -- recent-files picker (see <leader>fo above): the chord tier is a fixed
    -- budget, and resuming a file is reached for more often than the outline
    -- of the current one.
    --
    -- <C-s> for the workspace: s as in symbol, the same letter the <leader>
    -- twins carry. It was <C-l>, which is also Vim's redraw and oil's refresh,
    -- so the move gives a mnemonic and frees a chord that had two other jobs.
    -- Terminals send <C-s> as byte 0x13, and Neovim's TUI turns off XON/XOFF
    -- flow control, so it arrives through Zellij like the other chords.
    vim.keymap.set('n', '<leader>ss', search_document_symbols, { desc = 'Search Symbols (document)' })
    vim.keymap.set('n', '<C-s>', search_workspace_symbols, { desc = 'Search Symbols (workspace)' })
    vim.keymap.set('n', '<leader>sS', search_workspace_symbols, { desc = 'Search Symbols (workspace)' })

    -- gd lives in lsp.lua's LspAttach handler, buffer-local. It was bound here
    -- too, globally, to the identical function -- removed.

    --======================
    -- 3. Bug fixes
    --======================

    -- `x` is the diagnostic wherever it appears: g]/g[ move between them
    -- (lsp.lua), <leader>rx fixes the one under the cursor, and this lists them.
    -- Shift widens scope the same way it does for symbols, so the whole
    -- <leader>s group reads one way.
    vim.keymap.set('n', '<leader>sx', builtin.diagnostics, { desc = 'Search Diagnostics' })
    -- Fires workspace/diagnostic first so servers can report on files that were
    -- never opened (gopls supports it; ts_ls is push-only and ignores it), then
    -- scopes the results to cwd.
    vim.keymap.set('n', '<leader>sX', function()
      builtin.diagnostics { workspace = true, root_dir = true }
    end, { desc = 'Search Diagnostics (project-wide)' })

  end,
}
