-- Toggle Claude's pane -- or, with a visual selection, send it instead.
--
-- Sending is the one thing the chord does besides toggling. A selection is a
-- deliberate "this, to Claude", and ClaudeCodeSend has to run while it is still
-- live (it captures the range itself, then escapes), which is exactly how a Lua
-- keymap invokes it. Every other mode is a plain toggle, from inside the pane
-- too, where the buffer is a terminal and there is nothing to send. Nothing is
-- added to the composer on the way in: context arrives only when selected, or
-- through the <leader>c bindings below.
local function editor_columns()
  local columns = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_get_config(win).relative == ""
      and vim.bo[buf].buftype ~= "terminal"
      and not vim.wo[win].winfixwidth then
      columns[vim.fn.win_screenpos(win)[2]] = true
    end
  end
  return vim.tbl_count(columns)
end

local function claude_window()
  local buf = require("claudecode.terminal").get_active_terminal_bufnr()
  local win = buf and vim.fn.bufwinid(buf) or -1
  return win ~= -1 and win or nil
end

local function split_into_thirds(claude)
  vim.api.nvim_win_set_width(claude, math.floor(vim.o.columns / 3))
  vim.wo[claude].winfixwidth = true
  vim.cmd("horizontal wincmd =")
  vim.wo[claude].winfixwidth = false
end

local function toggle_claude_or_send()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- ClaudeCodeSend takes no side of its own: it opens through the configured
    -- default. A send therefore lands on the right unless the pane is already
    -- up, in which case it goes wherever the pane already is.
    vim.cmd("ClaudeCodeSend")
    return
  end
  -- focus_toggle, not simple_toggle: the ClaudeCode command this replaced was
  -- focus_toggle, so a visible-but-unfocused pane is focused rather than
  -- hidden. The side is only read when the pane is being opened.
  local was_open = claude_window() ~= nil
  local thirds = editor_columns() >= 2
  require("claudecode.terminal").focus_toggle {
    split_side = "right",
    split_width_percentage = thirds and 1 / 3 or 0.6,
  }
  local claude = claude_window()
  if thirds and claude and not was_open then
    split_into_thirds(claude)
  end
end

return {
  -- Claude Code in Neovim: pairs the editor with the Claude Code CLI
  -- https://github.com/coder/claudecode.nvim
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        -- Open/focus the Claude terminal in Normal mode; <i> to start typing.
        -- Also preserves scroll position when refocusing.
        auto_insert = true,
        split_width_percentage = 0.6,
      },
      -- Land in Claude's prompt after sending context, instead of only revealing
      -- the split beside the file. Upstream defaults to false, which routes sends
      -- through ensure_visible() -- deliberately no focus -- and `auto_insert` is
      -- gated on focus, so you'd otherwise stay in the file in Normal mode.
      focus_after_send = true,
    },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    -- Upstream defaults use a <leader>a prefix, which vim-test already takes
    keys = {
      { "<leader>c", nil, desc = "AI/Claude Code" },
      -- The same function object as <C-]> below, so the twin cannot drift from
      -- the chord; in Normal mode there is never a selection, so it only toggles.
      { "<leader>cc", toggle_claude_or_send, desc = "Toggle Claude" },
      -- Toggles the pane from every mode, including from inside it, and sends
      -- the selection when there is one. <C-]>'s only built-in is the ctags
      -- jump, and navigation here is entirely LSP with no tags file anywhere,
      -- so nothing is given up. Audited free of oil, fugitive, telescope and
      -- blink.cmp too. Terminals send it as 0x1D, so it needs no kitty
      -- keyboard protocol support.
      {
        "<C-]>",
        toggle_claude_or_send,
        mode = { "n", "i", "v", "x", "t" },
        desc = "Toggle Claude (or send selection)",
      },
      { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>cC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>cs",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "oil", "NvimTree", "neo-tree", "minifiles", "netrw", "snacks_picker_list" },
      },
      { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  }
}
