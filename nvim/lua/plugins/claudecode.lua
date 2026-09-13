-- Keystrokes that empty Claude's composer, sent straight to the PTY so Neovim's
-- own mappings never see them.
--
-- Not ctrl+l. It is still named `chat:clearInput` in Claude Code's Chat keymap,
-- but since 2.1.x it shares a handler with `chat:clearScreen`: a full redraw
-- that keeps the input. The composer's own line editor is what still deletes
-- text -- ctrl+k kills to the end of the line, ctrl+u to its start, and either
-- one pressed at a line boundary eats the newline. So a burst of each, kill
-- forward then kill backward, clears every line on both sides of the cursor.
-- Twenty of each covers a draft of ten lines either way.
--
-- The whole thing has to stay under 64 bytes. Claude Code reads a larger
-- single chunk from the PTY as a paste rather than as keystrokes, and a paste
-- of control bytes is dropped whole (measured on 2.1.270: 48 bytes land, 64
-- do not). One chansend, no timers, so the wipe stays synchronous and always
-- beats a mention riding the plugin's 50ms debounce.
local CLAUDE_CLEAR_INPUT = string.rep("\11", 20) .. string.rep("\21", 20)

-- Explorer buffers, where the cursor sits on a directory listing rather than in
-- a file. Matches the filetypes claudecode.nvim's own tree extractors support
-- (claudecode/integrations.lua) -- and the ft list on <leader>cs below.
local EXPLORER_FILETYPES = {
  oil = true,
  NvimTree = true,
  ["neo-tree"] = true,
  minifiles = true,
  netrw = true,
  snacks_picker_list = true,
}

-- Whether Claude's terminal buffer is showing in a window of the current tab.
-- Only the plain `ClaudeCode` toggle can hide it, and only when it is on screen,
-- so every "toggle" below asks this first.
local function claude_is_visible(term_bufnr)
  if not term_bufnr then
    return false
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == term_bufnr then
      return true
    end
  end
  return false
end

-- Toggle Claude, handing it whatever context the cursor sits on: the visual
-- selection if there is one, else the tree entry under the cursor (file or
-- folder) in an explorer, else the current file, else nothing.
--
-- `ClaudeCodeSend`/`ClaudeCodeAdd` both open (or launch) the terminal on their
-- own -- they queue the @ mention when Claude isn't connected yet -- so either
-- doubles as the "open" half of the toggle. Only the plain `ClaudeCode` toggle
-- can hide the terminal.
local function toggle_claude_with_context()
  local terminal_ok, terminal = pcall(require, "claudecode.terminal")
  local term_bufnr = terminal_ok and terminal.get_active_terminal_bufnr() or nil

  -- Each press starts clean. @ mentions are inserted into Claude's composer and
  -- left unsubmitted, so without this they pile up across presses (`@a.lua
  -- @b.lua @a.lua`). chansend is synchronous while the mention rides a 50ms
  -- debounce, so the wipe always lands first. Guarded on a live pane because
  -- send_to_terminal warns when there's no terminal -- noise on every cold start.
  local function send_with_clean_prompt(cmd)
    if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
      terminal.send_to_terminal(CLAUDE_CLEAR_INPUT, { submit = false })
    end
    vim.cmd(cmd)
  end

  -- Visual first, and unconditionally: sending the selection beats hiding, and
  -- you can't be in visual mode inside Claude's terminal buffer anyway.
  -- ClaudeCodeSend has to run while the selection is still live (it captures the
  -- range itself, then escapes), which is exactly how a Lua keymap invokes it.
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    send_with_clean_prompt("ClaudeCodeSend")
    return
  end

  -- Terminal already on screen: plain toggle hides it, and re-sending context on
  -- the way out would be wrong.
  if claude_is_visible(term_bufnr) then
    vim.cmd("ClaudeCode")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- In an explorer, mention the entry under the cursor -- a folder as readily as
  -- a file, since the extractors return directory paths too. TreeAdd only *logs*
  -- when extraction fails (cursor on `..`, empty picker), which would leave a
  -- toggle press doing nothing, so probe the same extractor first and fall back
  -- to opening bare.
  if EXPLORER_FILETYPES[vim.bo[bufnr].filetype] then
    local integrations_ok, integrations = pcall(require, "claudecode.integrations")
    local files = integrations_ok and integrations.get_selected_files_from_tree() or nil
    if files and #files > 0 then
      send_with_clean_prompt("ClaudeCodeTreeAdd")
    else
      vim.cmd("ClaudeCode")
    end
    return
  end

  -- Only real, on-disk files: ClaudeCodeAdd errors on anything it can't read,
  -- which rules out unsaved buffers, help, quickfix, etc.
  local name = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].buftype == "" and name ~= "" and vim.fn.filereadable(name) == 1 then
    send_with_clean_prompt("ClaudeCodeAdd %:p")
  else
    vim.cmd("ClaudeCode")
  end
end

-- Toggle Claude's pane -- or, with a visual selection, send it instead.
--
-- Sending is the one thing the chord does besides toggling. A selection is a
-- deliberate "this, to Claude", and ClaudeCodeSend has to run while it is still
-- live (it captures the range itself, then escapes), which is exactly how a Lua
-- keymap invokes it. Every other mode is a plain toggle, from inside the pane
-- too, where the buffer is a terminal and there is nothing to send. Nothing is
-- added to the composer on the way in: context arrives only when selected, or
-- through <leader><leader>, which mentions the file or tree entry under the
-- cursor.
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
      -- Same toggle, but hands Claude the context under the cursor. Normal and
      -- visual only: <leader> is Space, which just types a space in insert and
      -- terminal mode -- <C-]> above is the way in from there.
      {
        "<leader><leader>",
        toggle_claude_with_context,
        mode = { "n", "x" },
        desc = "Toggle Claude with context",
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
