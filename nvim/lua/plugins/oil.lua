return {
  -- Neovim file explorer: edit your filesystem like a buffer
  -- https://github.com/stevearc/oil.nvim
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {},
    config = function ()
      require("oil").setup({
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
      -- for <C-p> or <C-j> to step to, so oil's own close is used there instead:
      -- it puts the original buffer back in the same window.
      --
      -- Opening reaches from every mode. From inside the shell or Claude's pane
      -- it first steps to an editor window (config/panes.lua), the same as <C-p>
      -- and <C-j>: split in place, the explorer would open inside the pane and a
      -- picked file would land there too. The pane is then resized to half the
      -- screen so the drawer and the file have room beside it. Insert and
      -- visual mode are left before the split, since the explorer is a buffer
      -- to be read and edited in Normal mode. Hiding touches none of that: the
      -- mode and the window the press came from are left as they were.
      local DRAWER_WIDTH = 30

      local function is_ordinary_window(win)
        return vim.api.nvim_win_get_config(win).zindex == nil
      end
      local function is_editor_window(win)
        return is_ordinary_window(win)
          and vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= 'terminal'
      end
      local function is_oil_window(win)
        return is_ordinary_window(win)
          and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'oil'
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

      local function open_oil_beside()
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '\22' or mode == 's' or mode == 'S' then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
        end
        vim.cmd.stopinsert()
        local panes = require('config.panes')
        local from_pane = panes.leave_terminal_window()
        vim.cmd(('leftabove %dvsplit | Oil'):format(DRAWER_WIDTH))
        vim.wo.winfixwidth = true
        if from_pane then
          panes.balance_panes()
        end
      end

      local function toggle_oil_beside()
        if not hide_oil() then
          open_oil_beside()
        end
      end
      vim.keymap.set('n', '<leader>-', toggle_oil_beside, { desc = 'Toggle File Explorer (left split)' })
      -- The chord twin, binding the same function. <C-\> is byte 0x1C, so it
      -- arrives through Zellij with no kitty keyboard protocol support. <C-[>
      -- could not serve here: it is byte 0x1B, the same byte as <Esc>, so
      -- binding it would rebind Escape itself.
      vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-\\>', toggle_oil_beside, { desc = 'Toggle File Explorer (left split)' })
    end
  }
}
