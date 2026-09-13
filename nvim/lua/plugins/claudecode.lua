-- Toggle Claude's pane -- or, with a visual selection, send it instead.
--
-- Sending is the one thing the chord does besides toggling. A selection is a
-- deliberate "this, to Claude", and ClaudeCodeSend has to run while it is still
-- live (it captures the range itself, then escapes), which is exactly how a Lua
-- keymap invokes it. Every other mode is a plain toggle, from inside the pane
-- too, where the buffer is a terminal and there is nothing to send. Nothing is
-- added to the composer on the way in: context arrives only when selected, or
-- through the <leader>c bindings below.
local function toggle_claude_or_send()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("ClaudeCodeSend")
    return
  end
  vim.cmd("ClaudeCode")
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
        split_width_percentage = 0.75,
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
      { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      -- Toggles the pane from every mode, including from inside it, and sends
      -- the selection when there is one. <C-]>'s only built-in is the ctags
      -- jump, and navigation here is entirely LSP (gd/gr/gi/gy in lsp.lua) with
      -- no tags file anywhere, so nothing is given up. Audited free of oil,
      -- fugitive, telescope and blink.cmp too. Terminals send it as 0x1D, so it
      -- needs no kitty keyboard protocol support.
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
