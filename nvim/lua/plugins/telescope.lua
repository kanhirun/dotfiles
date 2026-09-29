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
    local actions = require 'telescope.actions'

    local picker_keys = {
      i = { ['<C-s>'] = actions.select_vertical },
      n = { ['<C-s>'] = actions.select_vertical },
    }
    for _, chord in ipairs { '<C-g>' } do
      local function switch(prompt_bufnr)
        actions.close(prompt_bufnr)
        vim.schedule(function()
          vim.api.nvim_feedkeys(vim.keycode(chord), 'm', false)
        end)
      end
      picker_keys.i[chord] = switch
      picker_keys.n[chord] = switch
    end

    require('telescope').setup {
      defaults = {
        -- `%.git/` needs the slash: `.github/` must stay in. It is only
        -- reached now that find_files walks hidden files (see find_files below).
        file_ignore_patterns = { 'node_modules', 'generated', '%.git/' },
        -- <C-s> opens the pick in a vertical split, the key oil.lua gives the
        -- same action, so both listings split the same way. Telescope's own
        -- <C-v> stays. The picker's buffer-local map wins over the global
        -- <C-s> workspace-symbols chord while a picker is open. Both modes,
        -- since a pick is made from either.
        mappings = picker_keys,
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
    -- oil's <C-q> in oil.lua, so both reach from a pane the same way.
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

    -- The files changed in the working tree: modified, staged, and untracked
    -- but not ignored -- what `git status` reports. git_files was the wrong
    -- list; it returns every file in the repo, which <leader>fF already covers.
    local function find_git_changes()
      local from_pane = panes.leave_terminal_window()
      local function attach()
        if from_pane then
          require('telescope.actions.set').select:enhance { post = panes.balance_panes }
        end
        return true
      end

      -- git_status raises outside a work tree, which the dotfiles-adjacent and
      -- scratch directories are; rg covers those the way <leader>fF does.
      local repo = vim.system({ 'git', 'rev-parse', '--is-inside-work-tree' }, { cwd = vim.uv.cwd(), text = true }):wait()
      if repo.code ~= 0 then
        return builtin.find_files { hidden = true, attach_mappings = attach }
      end

      builtin.git_status { attach_mappings = attach }
    end

    -- <C-g> is the git chord: g for git. It held live_grep before, which is
    -- leader-only now (see <leader>sg below). Every mode, like <C-f>, so it
    -- reaches from inside the shell and Claude's pane; there it displaces
    -- readline's abort-line, which <C-c> also does. <C-g> is BEL (0x07), a
    -- legacy control byte that arrives through Zellij with no kitty keyboard
    -- protocol support. Normal mode's default <C-g> only prints the file name,
    -- which the statusline already shows.
    --
    -- <leader>fg is the leader twin, and reads as find-git either way round.
    vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-g>', find_git_changes, { desc = '[G]it changes' })
    vim.keymap.set('n', '<leader>fg', find_git_changes, { desc = '[f]ind [g]it changes' })

    -- The cwd's recent files, most recent first. options.lua raises the shada
    -- cap to 1000 precisely so this per-project slice is not starved; there is
    -- no further limit here, and the fuzzy matcher narrows the rest.
    local function search_recent_files()
      local from_pane = panes.leave_terminal_window()
      local cwd = vim.uv.cwd()
      local results, seen = {}, {}

      for _, path in ipairs(vim.v.oldfiles) do
        local abs = vim.fs.normalize(path)
        -- oldfiles keeps paths that have since been deleted, hence fs_stat.
        if
          not seen[abs]
          and not path:match '%.git/COMMIT_EDITMSG$'
          and vim.startswith(abs, cwd .. '/')
          and vim.uv.fs_stat(abs)
        then
          seen[abs] = true
          -- gen_from_file joins relative paths against cwd and displays them as-is
          table.insert(results, abs:sub(#cwd + 2))
        end
      end

      local conf = require('telescope.config').values
      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Recent Files',
          finder = require('telescope.finders').new_table {
            results = results,
            entry_maker = require('telescope.make_entry').gen_from_file { cwd = cwd },
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

    -- <leader>ff is the recent files, <leader>fF every file: the doubled key
    -- is the group's default and recent files are the usual pick, and Shift
    -- widens the same list from what was opened here to everything on disk.
    -- Recent files were <leader>fr before, and <leader>fo before that, for
    -- vim's own `:oldfiles`, back when the list also carried the uncommitted
    -- files; that had a <C-k> chord too, now unmapped.
    --
    -- <C-f> is the file chord: f is the noun's letter, the same one the
    -- <leader>f pair carries. It sits on the pair's default, so it and
    -- <leader>ff bind the same function and the wide picker is leader-only.
    -- It replaced <C-p>, which used to open this same picker and is now
    -- unbound outside the completion menu. Every mode, like <C-q> and <C-\>,
    -- and `t` is the one that matters: it makes the chord reach from inside
    -- the shell and Claude's pane, which otherwise swallow it (readline
    -- forward-char, which Right also does). <C-f> is a legacy control byte
    -- (0x06), so it arrives through Zellij with no kitty keyboard protocol
    -- support.
    vim.keymap.set('n', '<leader>ff', search_recent_files, { desc = '[f]ind recent [f]iles' })
    vim.keymap.set('n', '<leader>fF', find_files, { desc = '[f]ind all [F]iles' })

    -- Search directories only; selecting one opens it in oil.nvim.
    -- fd respects .gitignore; the 'find' fallback does not, so it will surface
    -- build output (cdk.out, dist, ...) in repos that gitignore it.
    local function search_directories()
      local from_pane = panes.leave_terminal_window()
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
              if from_pane then
                panes.balance_panes()
              end
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

    -- Jump to any directory zoxide knows about (same database as `j` in the
    -- shell) and open it in oil. The picker opens on the full frecency
    -- ranking, so an empty prompt is a reminder of where you actually go;
    -- typing narrows it with telescope's fuzzy matcher rather than zoxide's
    -- own query resolution.
    local function zoxide_entries()
      local out = vim.system({ 'zoxide', 'query', '--list', '--score', '--base-dir', vim.fn.getcwd() }, { text = true }):wait()
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
        return vim.notify('No frecent directories under ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~'), vim.log.levels.WARN)
      end

      local displayer = require('telescope.pickers.entry_display').create {
        separator = '  ',
        items = { { width = score_width }, { remaining = true } },
      }

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Frecent directories',
          finder = require('telescope.finders').new_table {
            results = entries,
            -- Only the path is the ordinal, so the score never fuzzy-matches.
            entry_maker = function(item)
              local shown = item.dir == vim.fn.getcwd() and '.' or vim.fn.fnamemodify(item.dir, ':.')
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

              vim.schedule(function()
                require('config.zoxide').add(entry.value)
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

    vim.keymap.set('n', '<leader>fd', jump_to_zoxide_directory, { desc = '[f]ind frecent [d]ir' })
    vim.keymap.set('n', '<leader>fD', search_directories, { desc = '[f]ind all [D]ir' })

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

    -- Leader-only now that <C-g> carries git changes, and <leader>sg is where the
    -- Find/Search split puts it: a grep searches content, not names.
    vim.keymap.set('n', '<leader>sg', live_grep, { desc = '[s]earch by [g]rep' })

    -- Kinds worth jumping to. Telescope lowercases these before comparing, so
    -- they match the LSP kind names; drop the list to get everything back.
    --
    -- `constant` is what the server calls it, and servers differ on when they
    -- do: gopls and lua_ls report `const` as constant, ts_ls reports a
    -- top-level `const` as variable and keeps constant for enum-like cases.
    -- `variable` is left out on purpose, since it would bring every `let` in.
    local SYMBOL_KINDS = { 'function', 'method', 'class', 'struct', 'interface', 'constant' }
    local CLASS_KINDS = { 'class', 'struct', 'interface' }
    local METHOD_KINDS = { 'function', 'method' }

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
    -- list needs the filter the file pickers get for free from rg. Anything
    -- outside the repo is dropped too: gopls is told symbolScope=workspace in
    -- lsp.lua, but other servers still answer with stdlib and installed deps
    -- (pyright's site-packages under ~/.pyenv, say), and the picker is meant
    -- to cover the project, not the toolchain.
    --
    -- The path set is gathered here rather than inside the finder: the dynamic
    -- finder runs in plenary's async context, where a blocking wait isn't safe.
    local function kind_of(item)
      return (item.kind or item.text:match '^%[(.-)%]' or ''):lower()
    end

    local function wanted(item, kinds)
      return vim.tbl_contains(kinds or SYMBOL_KINDS, kind_of(item))
    end

    local function record_pick()
      local entry = require('telescope.actions.state').get_selected_entry()
      if entry and entry.value then
        require('config.symbol_history').record(entry.value)
      end
    end

    local function attach_history()
      require('telescope.actions.set').select:enhance { pre = record_pick }
      return true
    end

    local function open_buffer_symbols(kinds)
      local bufs = vim.tbl_filter(function(info)
        return vim.bo[info.bufnr].buftype == ''
          and info.name ~= ''
          and #vim.lsp.get_clients { bufnr = info.bufnr, method = 'textDocument/documentSymbol' } > 0
      end, vim.fn.getbufinfo { buflisted = 1, bufloaded = 1 })
      local current = vim.api.nvim_get_current_buf()
      table.sort(bufs, function(a, b)
        if (a.bufnr == current) ~= (b.bufnr == current) then
          return a.bufnr == current
        end
        return a.lastused > b.lastused
      end)

      local per_buf, pending = {}, #bufs
      for i, info in ipairs(bufs) do
        per_buf[i] = {}
        vim.lsp.buf_request_all(
          info.bufnr,
          'textDocument/documentSymbol',
          { textDocument = vim.lsp.util.make_text_document_params(info.bufnr) },
          function(results)
            for client_id, res in pairs(results) do
              local client = vim.lsp.get_client_by_id(client_id)
              if res.result and client then
                vim.list_extend(per_buf[i], vim.lsp.util.symbols_to_items(res.result, info.bufnr, client.offset_encoding))
              end
            end
            pending = pending - 1
          end
        )
      end
      vim.wait(500, function()
        return pending == 0
      end, 10)

      local items = {}
      for _, list in ipairs(per_buf) do
        for _, item in ipairs(list) do
          if wanted(item, kinds) then
            table.insert(items, item)
          end
        end
      end
      return items
    end

    local function recent_symbols(kinds)
      local seen, seed = {}, {}
      local function add(item)
        local key = vim.fs.normalize(item.filename) .. '\0' .. item.text
        if not seen[key] then
          seen[key] = true
          table.insert(seed, item)
        end
      end
      for _, item in ipairs(require('config.symbol_history').list()) do
        if wanted(item, kinds) then
          add(item)
        end
      end
      for _, item in ipairs(open_buffer_symbols(kinds)) do
        add(item)
      end
      return seed
    end

    local function match_rank(prompt, text)
      local name = text:match '^%[.-%]%s+(.*)$' or text
      local leaf = name:match '[%w_$]+$' or name
      local q, lname, lleaf = prompt:lower(), name:lower(), leaf:lower()
      if lleaf == q or lname == q then
        return 0
      end
      if vim.startswith(lleaf, q) or vim.startswith(lname, q) then
        return 1
      end
    end

    local function rank_symbols(items, prompt, current_file)
      local keyed = {}
      for i, item in ipairs(items) do
        local rank = match_rank(prompt, item.text)
        if rank then
          table.insert(keyed, {
            item = item,
            rank = rank,
            elsewhere = vim.fs.normalize(item.filename or '') == current_file and 0 or 1,
            index = i,
          })
        end
      end
      table.sort(keyed, function(a, b)
        if a.rank ~= b.rank then
          return a.rank < b.rank
        end
        if a.elsewhere ~= b.elsewhere then
          return a.elsewhere < b.elsewhere
        end
        return a.index < b.index
      end)
      return vim.tbl_map(function(k)
        return k.item
      end, keyed)
    end

    local function workspace_requester(bufnr, kinds)
      local current_file = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
      local channel = require('plenary.async.control').channel
      local cancel = function() end
      return function(prompt)
        local tx, rx = channel.oneshot()
        cancel()
        cancel = vim.lsp.buf_request_all(bufnr, 'workspace/symbol', { query = prompt }, tx)
        local items = {}
        for client_id, res in pairs(rx()) do
          local client = vim.lsp.get_client_by_id(client_id)
          if res.error then
            vim.schedule(function()
              vim.notify('workspace/symbol: ' .. res.error.message, vim.log.levels.ERROR)
            end)
          elseif res.result and client then
            for _, item in ipairs(vim.lsp.util.symbols_to_items(res.result, bufnr, client.offset_encoding)) do
              if wanted(item, kinds) then
                table.insert(items, item)
              end
            end
          end
        end
        return rank_symbols(items, prompt, current_file)
      end
    end

    local function search_workspace_symbols(kinds, title)
      local git = git_paths()
      local seed = recent_symbols(kinds)
      local query = workspace_requester(vim.api.nvim_get_current_buf(), kinds)
      local inner = require('telescope.make_entry').gen_from_lsp_symbols {}
      local conf = require('telescope.config').values

      require('telescope.pickers')
        .new({}, {
          prompt_title = title or 'Workspace Symbols',
          finder = require('telescope.finders').new_dynamic {
            entry_maker = function(item)
              local entry = inner(item)
              if not entry or not git or not entry.filename then
                return entry
              end
              local abs = vim.fs.normalize(entry.filename)
              if not vim.startswith(abs, git.root .. '/') or not git.paths[abs] then
                return nil
              end
              return entry
            end,
            fn = function(prompt)
              if prompt == '' then
                return seed
              end
              return query(prompt)
            end,
          },
          previewer = conf.qflist_previewer {},
          sorter = require('telescope.sorters').highlighter_only {},
          attach_mappings = function(_, map)
            map('i', '<c-space>', require('telescope.actions').to_fuzzy_refine)
            return attach_history()
          end,
        })
        :find()
    end

    -- Document symbols only ever cover the current buffer, so the gitignore
    -- filter has nothing to do here; the kind list still earns its place.
    local function search_document_symbols(kinds)
      builtin.lsp_document_symbols { symbols = kinds or SYMBOL_KINDS, attach_mappings = attach_history }
    end

    -- One function per scope. lsp.lua used to bind <leader>gs/<leader>gS to
    -- the same builtins with no options at all -- the same capability,
    -- silently unfiltered, at other addresses. Those are deleted; these three
    -- are the only symbol entry points.
    --
    -- Document symbols are leader-only. They had <C-k>, which is now unmapped.
    --
    -- <C-s> for the workspace: s as in symbol, the same letter the <leader>
    -- twins carry. It was <C-l>, which is also Vim's redraw and oil's refresh,
    -- so the move gives a mnemonic and frees a chord that had two other jobs.
    -- Terminals send <C-s> as byte 0x13, and Neovim's TUI turns off XON/XOFF
    -- flow control, so it arrives through Zellij like the other chords.
    vim.keymap.set('n', '<leader>ss', search_document_symbols, { desc = '[s]earch [s]ymbols' })
    vim.keymap.set('n', '<C-s>', search_document_symbols, { desc = '[S]ymbols in this buffer' })
    vim.keymap.set('n', '<leader>fs', search_workspace_symbols, { desc = '[f]ind [s]ymbol' })
    vim.keymap.set('n', '<C-M-s>', search_workspace_symbols, { desc = 'all [S]ymbols' })
    vim.keymap.set('n', '<leader>fc', function()
      search_workspace_symbols(CLASS_KINDS, 'Classes')
    end, { desc = '[f]ind [c]lass' })
    vim.keymap.set('n', '<leader>fm', function()
      search_workspace_symbols(METHOD_KINDS, 'Methods')
    end, { desc = '[f]ind [m]ethod' })
    vim.keymap.set('n', '<leader>sc', function()
      search_document_symbols(CLASS_KINDS)
    end, { desc = '[s]earch [c]lasses' })
    vim.keymap.set('n', '<leader>sm', function()
      search_document_symbols(METHOD_KINDS)
    end, { desc = '[s]earch [m]ethods' })

    -- gd lives in lsp.lua's LspAttach handler, buffer-local. It was bound here
    -- too, globally, to the identical function -- removed.

    --======================
    -- 3. Bug fixes
    --======================

    -- `x` is the diagnostic wherever it appears: ]x/[x move between them
    -- (lsp.lua), <leader>rx fixes the one under the cursor, and this lists them.
    -- Shift widens scope the same way it does for symbols, so the whole
    -- <leader>s group reads one way.
    vim.keymap.set('n', '<leader>sx', builtin.diagnostics, { desc = '[s]earch diagnostics [x]' })
    -- Fires workspace/diagnostic first so servers can report on files that were
    -- never opened (gopls supports it; ts_ls is push-only and ignores it), then
    -- scopes the results to cwd.
    vim.keymap.set('n', '<leader>sX', function()
      builtin.diagnostics { workspace = true, root_dir = true }
    end, { desc = '[s]earch all diagnostics [X]' })

  end,
}
