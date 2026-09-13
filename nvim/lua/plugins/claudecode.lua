-- ctrl+l is `chat:clearInput` in Claude Code's Chat keymap. Sent straight to the
-- PTY, so Neovim's own mappings never see it. NOT ctrl+u, which Claude binds to
-- scroll:halfPageUp -- that would scroll the transcript and leave the prompt as is.
local CLAUDE_CLEAR_INPUT = "\12"

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
  if term_bufnr then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(win) == term_bufnr then
        vim.cmd("ClaudeCode")
        return
      end
    end
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

-- Paths already mentioned in Claude's composer, as a set. Scoped to one terminal
-- session: a new pane means a new composer, so the set is dropped when the
-- terminal bufnr changes rather than persisting across restarts.
local mentioned = {}
local mentioned_term = nil

local function reset_set_for(term_bufnr)
  if term_bufnr ~= mentioned_term then
    mentioned, mentioned_term = {}, term_bufnr
  end
end

-- Add the cursor's context to Claude, skipping anything already mentioned.
--
-- The counterpart to toggle_claude_with_context: that one WIPES the composer and
-- sends one thing, this one ACCUMULATES without duplicating. Between them you can
-- either build a context set up or replace it wholesale, which is why <C-]> stops
-- sending CLAUDE_CLEAR_INPUT -- clearing is the other key's job now.
--
-- Known limit: Claude consumes the mentions when you submit, and nothing reports
-- that back, so the set goes stale on the first Enter. Re-adding a file then
-- looks like a no-op. <leader><leader> is the escape hatch -- it clears and
-- re-sends regardless of the set.
local function add_claude_context()
  local terminal_ok, terminal = pcall(require, "claudecode.terminal")
  local term_bufnr = terminal_ok and terminal.get_active_terminal_bufnr() or nil
  reset_set_for(term_bufnr)

  -- Visual first and never deduped: a selection is a range, not an identity, and
  -- ClaudeCodeSend has to run while it is still live. Sending also ends visual
  -- mode, so the same selection can't easily be sent twice anyway.
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("ClaudeCodeSend")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- oil is showing a directory, and the directory is the useful unit -- not
  -- whichever row the cursor happens to rest on. claudecode's own oil extractor
  -- returns the entry under the cursor, so TreeAdd is the wrong call here;
  -- ClaudeCodeAdd takes a directory directly (it checks isdirectory alongside
  -- filereadable) and mentions it as one.
  if vim.bo[bufnr].filetype == "oil" then
    local oil_ok, oil = pcall(require, "oil")
    local dir = oil_ok and oil.get_current_dir(bufnr) or nil
    if dir then
      -- Trailing slash stripped so the set key matches what a file path would
      -- normalize to, and the same folder can't be mentioned under two spellings.
      local path = vim.fs.normalize(dir):gsub("/$", "")
      if not mentioned[path] then
        vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(path))
        mentioned[path] = true
        return
      end
    end
    vim.cmd("ClaudeCode")
    return
  end

  -- Every other explorer: the entry under the cursor. TreeAdd mentions whatever it
  -- extracts and takes no filter, so the set is checked over the whole extraction:
  -- every path already mentioned means there is nothing to add and the press
  -- falls through to a plain toggle.
  if EXPLORER_FILETYPES[vim.bo[bufnr].filetype] then
    local integrations_ok, integrations = pcall(require, "claudecode.integrations")
    local files = integrations_ok and integrations.get_selected_files_from_tree() or nil
    if files and #files > 0 then
      local fresh = false
      for _, path in ipairs(files) do
        if not mentioned[vim.fs.normalize(path)] then
          fresh = true
        end
      end
      if fresh then
        vim.cmd("ClaudeCodeTreeAdd")
        for _, path in ipairs(files) do
          mentioned[vim.fs.normalize(path)] = true
        end
        return
      end
    end
    vim.cmd("ClaudeCode")
    return
  end

  -- Only real, on-disk files: ClaudeCodeAdd errors on anything it can't read,
  -- which rules out unsaved buffers, help, quickfix -- and Claude's own terminal,
  -- so pressing this from inside the pane still just toggles it away.
  local name = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].buftype == "" and name ~= "" and vim.fn.filereadable(name) == 1 then
    local path = vim.fs.normalize(name)
    if not mentioned[path] then
      vim.cmd("ClaudeCodeAdd %:p")
      mentioned[path] = true
      return
    end
  end

  -- Nothing new to say: show Claude, or hide it if it is already on screen.
  vim.cmd("ClaudeCode")
end

-- Open Claude on an empty composer: wipe the queued mentions and drop the set
-- that tracks them, so <C-]> starts accumulating from nothing again. Open rather
-- than toggle -- "start a fresh prompt" should never hide the pane you asked for.
local function open_claude_clear()
  local terminal_ok, terminal = pcall(require, "claudecode.terminal")
  local term_bufnr = terminal_ok and terminal.get_active_terminal_bufnr() or nil
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    terminal.send_to_terminal(CLAUDE_CLEAR_INPUT, { submit = false })
  end
  mentioned, mentioned_term = {}, term_bufnr
  vim.cmd("ClaudeCodeOpen")
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
      -- Adds the cursor's context to Claude without duplicating it, and toggles
      -- the pane when there is nothing new to add -- including from inside the
      -- pane itself, where the buffer is not a file and so never has anything.
      -- <C-]>'s only built-in is the ctags jump, and navigation here is entirely
      -- LSP (gd/gr/gi/gy in lsp.lua) with no tags file anywhere, so nothing is
      -- given up. Audited free of oil, fugitive, telescope and blink.cmp too.
      -- Terminals send it as 0x1D, so it needs no kitty keyboard protocol support.
      {
        "<C-]>",
        add_claude_context,
        mode = { "n", "i", "v", "x", "t" },
        desc = "Add context to Claude (or toggle)",
      },
      -- Normal mode only, and that is what makes it affordable. <C-\> is the
      -- universal escape (config/keymaps.lua) -- but in Normal mode the escape
      -- has almost nothing to do, since Esc there only cancels a pending count or
      -- operator. Every mode where the escape actually earns its keep -- insert,
      -- visual, select, operator-pending and terminal -- keeps it untouched.
      {
        "<C-\\>",
        open_claude_clear,
        mode = "n",
        desc = "Open Claude, clear context",
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
