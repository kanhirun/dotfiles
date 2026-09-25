return {
  -- Neovim file explorer: edit your filesystem like a buffer
  -- https://github.com/stevearc/oil.nvim
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {},
    config = function ()
      require("oil").setup({
        -- Oil reads a directory once and holds that listing. Anything that
        -- changes the tree from outside Neovim -- a shell, a git checkout --
        -- leaves the buffer showing a snapshot, with no sign it is stale.
        -- Costs a libuv watcher per open oil buffer.
        watch_for_changes = true,
        use_default_keymaps = false,
        keymaps = {
          ["g?"] = { "actions.show_help", mode = "n" },
          ["<CR>"] = "actions.select",
          ["<C-s>"] = { "actions.select", opts = { vertical = true } },
          ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
          ["<C-t>"] = { "actions.select", opts = { tab = true } },
          ["gp"] = "actions.preview",
          ["gc"] = { "actions.close", mode = "n" },
          ["<C-l>"] = "actions.refresh",
          ["-"] = { "actions.parent", mode = "n" },
          ["_"] = { "actions.open_cwd", mode = "n" },
          ["`"] = { "actions.cd", mode = "n" },
          ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
          ["gs"] = { "actions.change_sort", mode = "n" },
          ["gx"] = "actions.open_external",
          ["g."] = { "actions.toggle_hidden", mode = "n" },
          ["g\\"] = { "actions.toggle_trash", mode = "n" },
        }
      })
      vim.keymap.set('n', '-', ':Oil<CR>', { noremap = true, desc = 'Open File Explorer' })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'oil',
        callback = function()
          local dir = require('oil').get_current_dir()
          if dir and vim.fn.exists('*ProjectionistDetectPath') == 1 then
            vim.fn.ProjectionistDetectPath(dir)
          end
        end,
      })

      -- Pairs with bare `-`: the same explorer, opened beside the file instead of
      -- over it, so the buffer being edited stays on screen. A toggle: with an
      -- explorer already showing in this tab, the press hides it instead of
      -- stacking a second split beside the first.
      --
      -- The explorer is a drawer, not a second page. A plain vsplit would halve
      -- the window, and a directory listing needs nothing like that: file names
      -- fit in a narrow column, and the file being edited is what the width is
      -- for. So the split is opened at a fixed width and pinned with
      -- winfixwidth, so opening or closing other windows does not re-equalize
      -- it back to a half.
      --
      -- Hiding closes the explorer's window, so the file it sat beside takes the
      -- space back. The one exception is an explorer that is the only editor
      -- window on screen -- bare `-` over the file, say, with Claude's pane
      -- beside it. Closing that window would leave the pane alone, with nothing
      -- for <C-f> or <C-j> to step to, so oil's own close is used there instead:
      -- it puts the original buffer back in the same window.
      --
      -- Opening reaches from every mode. From inside the shell or Claude's pane
      -- it first steps to an editor window (config/panes.lua), the same as <C-f>
      -- and <C-j>: split in place, the explorer would open inside the pane and a
      -- picked file would land there too. The pane is then resized to half the
      -- screen so the drawer and the file have room beside it. Insert and
      -- visual mode are left before the split, since the explorer is a buffer
      -- to be read and edited in Normal mode. Hiding touches none of that: the
      -- mode and the window the press came from are left as they were.
      -- Two drawers, one mechanism. The wide one splits beside the window you
      -- are in; the compact one pins itself to the screen's left edge, which is
      -- what `topleft` buys over `leftabove` -- the latter is relative to the
      -- current window, so from a right-hand split it lands mid-screen.
      local DRAWER_WIDTH = 30
      local COMPACT_WIDTH = 28

      local function is_ordinary_window(win)
        return vim.api.nvim_win_get_config(win).zindex == nil
      end
      local function is_editor_window(win)
        return is_ordinary_window(win)
          and vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= 'terminal'
      end
      -- Only the drawer counts. Oil opened into a regular window with :Oil or
      -- `-` is a buffer being browsed, and the toggle leaves it alone.
      local function is_oil_window(win)
        return is_ordinary_window(win) and vim.w[win].oil_drawer == true
      end

      local function hide_oil()
        local wins = vim.api.nvim_tabpage_list_wins(0)
        local oil_wins, editor_wins = {}, 0
        for _, win in ipairs(wins) do
          if is_oil_window(win) then
            table.insert(oil_wins, win)
          end
          if is_editor_window(win) then
            editor_wins = editor_wins + 1
          end
        end
        if #oil_wins == 0 then
          return false
        end
        for _, win in ipairs(oil_wins) do
          if editor_wins > 1 then
            vim.api.nvim_win_close(win, false)
            editor_wins = editor_wins - 1
          else
            vim.api.nvim_win_call(win, function()
              require('oil').close()
            end)
          end
        end
        return true
      end

      local function open_oil_beside(width, placement)
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '\22' or mode == 's' or mode == 'S' then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
        end
        vim.cmd.stopinsert()
        local panes = require('config.panes')
        local from_pane = panes.leave_terminal_window()
        vim.cmd(('%s %dvsplit | Oil'):format(placement, width))
        vim.wo.winfixwidth = true
        vim.w.oil_drawer = true
        if from_pane then
          panes.balance_panes()
        end
      end

      -- Closes the drawer if one is open, from inside it too. Otherwise opens
      -- one, unless the cursor is already in an oil buffer filling a regular
      -- window, where a drawer beside it would be oil next to oil: no-op.
      local function toggle_oil_beside(width, placement)
        if hide_oil() then
          return
        end
        if vim.bo.filetype == 'oil' then
          return
        end
        open_oil_beside(width, placement)
      end

      -- Either chord closes whichever drawer is open, so the two never stack.
      local toggle_drawer = function()
        toggle_oil_beside(DRAWER_WIDTH, 'leftabove')
      end
      local toggle_compact = function()
        toggle_oil_beside(COMPACT_WIDTH, 'topleft')
      end
      vim.keymap.set('n', '<leader>-', toggle_drawer, { desc = 'Toggle File Explorer (left split)' })
      -- The chord twin, binding the same function. <C-q> is byte 0x11, so it
      -- needs no kitty keyboard protocol support. It is XON, but Neovim's TUI
      -- turns off flow control, so it arrives like <C-s> does. It costs Vim's
      -- alternative to <C-v> (blockwise Visual in Normal mode, literal insert
      -- in Insert mode) and readline's quoted-insert inside the panes. Zellij
      -- binds Ctrl-q to quit by default; that binding has to be removed in
      -- the Zellij config or the chord never gets this far.
      --
      -- It was <C-a>, which is now unbound: that gave back Vim's increment
      -- and readline's beginning-of-line in the panes.
      vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-q>', toggle_drawer, { desc = 'Toggle File Explorer (left split)' })

      -- The compact drawer, at the screen's left edge whatever window you are
      -- in. <C-S-[> is the second binding in this config that depends on the
      -- kitty keyboard protocol: Ctrl and Shift on `[` has no legacy control
      -- byte of its own, and Ghostty reports it as its own keycode the way it
      -- already does for <C-S-Z>. Without that protocol nothing arrives -- it
      -- does not fall back to <Esc>, which plain <C-[> would be. <leader>_ is
      -- the twin, binding the same function; Shift on `-` means a variant here
      -- rather than a wider scope, which is a deviation and recorded as one.
      vim.keymap.set('n', '<leader>_', toggle_compact, { desc = 'Toggle File Explorer (compact, screen left)' })
      vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-S-[>', toggle_compact, { desc = 'Toggle File Explorer (compact, screen left)' })
    end
  }
}
