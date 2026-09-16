-- The shell's top edge, drawn as a rule across its winbar. A bottom split's
-- upper boundary is the statusline of the window above it, and this theme
-- paints inactive statuslines in the background colour (StatusLineNC fg == bg),
-- so with the shell focused the seam between it and the editor vanished.
-- Snacks already puts a winbar on bottom terminals ("1: zsh", in grey WinBar);
-- this keeps the title and turns the line into a border. Normal's fg is the
-- theme's white, and stays white across themes as the brightest colour there
-- is. The rule is sized to the window so nothing is truncated (a `<` would
-- otherwise appear).
local SHELL_WINBAR = table.concat({
  "%#Normal#",
  "%{empty(get(b:, 'term_title', '')) ? repeat('─', winwidth(0))",
  " : '── ' . b:term_title . ' ' . repeat('─', winwidth(0) - strdisplaywidth(b:term_title) - 4)}",
})

return {
  -- Terminal toggle
  -- https://github.com/folke/snacks.nvim
  {
    "folke/snacks.nvim",
    -- claudecode.nvim already pulls snacks in as a dependency, but nothing ever
    -- calls setup() on it, so the `Snacks` global is nil. An explicit spec with
    -- opts is what defines it; without this the keymap below has to go through
    -- require("snacks") instead.
    opts = {
      terminal = {
        -- Snacks opens the terminal as a bottom split at height 0.4. Values
        -- below 1 are read as a fraction of the editor height, so 3/4 is three
        -- quarters of the screen.
        win = { height = 3 / 4 },
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      -- One pane at a time. The <C-Space> shell and Claude's pane are both
      -- Snacks terminals, and showing either one hides the other, so the two
      -- never share the screen. Hiding is all it is: the shell and Claude keep
      -- running, and the next toggle brings the hidden one straight back.
      --
      -- Enforced here, on the buffer entering a window, rather than in the two
      -- toggles. The shell has one way in, but Claude has a dozen -- ClaudeCode,
      -- ClaudeCodeOpen, ClaudeCodeAdd, ClaudeCodeSend, ClaudeCodeTreeAdd,
      -- ClaudeCodeFocus, --resume, --continue -- and wrapping each would be one
      -- forgotten path away from both panes open. Snacks' own on_win hook is no
      -- use either: claudecode.nvim closes its split on hide and rebuilds it by
      -- hand on show (its climbing-cursor workaround), so on_win fires once, on
      -- first launch. BufWinEnter fires on every path: nvim_open_win on launch,
      -- nvim_win_set_buf on every re-show.
      --
      -- Snacks stamps b:snacks_terminal on every terminal buffer it owns, which
      -- is how a pane is told apart from a plain :terminal. Hiding goes through
      -- the instance's own hide() so Claude's takes claudecode's anchor-safe
      -- path and the shell's takes Snacks'. Nested so Snacks' WinClosed
      -- bookkeeping runs the same as it does for an interactive close.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("one_pane_at_a_time", { clear = true }),
        desc = "Hide the other pane when the shell or Claude is shown",
        nested = true,
        callback = function(ev)
          if not vim.b[ev.buf].snacks_terminal then
            return
          end
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if buf ~= ev.buf and vim.b[buf].snacks_terminal then
              for _, term in ipairs(Snacks.terminal.list()) do
                if term.buf == buf then
                  term:hide()
                end
              end
            end
          end
        end,
      })
    end,
    keys = {
      -- Mirrors <C-]> in claudecode.lua: bound in every mode including `t`,
      -- so the chord that opens the terminal also closes it from inside.
      -- Pressed from inside Claude's pane, it swaps the panes: the BufWinEnter
      -- rule above hides Claude as the shell appears.
      --
      -- <C-Space> echoes the Space leader and is unclaimed by Vim, blink.cmp,
      -- oil, fugitive and telescope. Terminals send it as NUL, so like <C-]>'s
      -- 0x1D it survives terminal mode with no kitty keyboard protocol support.
      {
        "<C-Space>",
        -- term_normal = false deletes snacks' own <Esc> handler for THIS terminal,
        -- letting the global t-mode <Esc> in config/keymaps.lua through. Snacks
        -- binds <Esc> buffer-locally to a 200ms double-tap, and buffer-local beats
        -- global, so without this a single <Esc> here does nothing.
        --
        -- Passed per call rather than in opts.terminal above, because that is
        -- shared configuration: claudecode.nvim opens its pane through the same
        -- Snacks.terminal, and Claude needs <Esc> for interrupt. This is a plain
        -- shell, so nothing here wants the key.
        function()
          Snacks.terminal.toggle(nil, {
            win = { keys = { term_normal = false }, wo = { winbar = SHELL_WINBAR } },
          })
        end,
        mode = { "n", "i", "v", "x", "t" },
        desc = "Toggle terminal",
      },
    },
  }
}
