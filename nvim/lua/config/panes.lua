-- The shell and Claude's pane are Snacks terminals that share the screen with
-- the editor. Anything that opens a file from inside one -- a picker, the
-- explorer -- goes through here so the file lands in an editor window and the
-- pane is resized to share the screen rather than replaced or hidden.
local M = {}

-- A picker hands its result to the window it was opened from. Opened from
-- inside the Snacks shell or Claude's pane, that window is a terminal,
-- and the file would replace the pane instead of opening beside it. So a
-- picker launched from a terminal window first steps to an editor window:
-- the one it came from if that is one, else the first ordinary split.
-- Cancelling the picker leaves everything as it was; a chord teleports,
-- it never mutates. With no editor window at all, the picker opens where
-- it is.
--
-- An editor window is any non-floating window that is not a terminal. Not
-- "buftype is empty", which is what Snacks' fixbuf checks: oil buffers are
-- `acwrite`, help and quickfix are `help` and `quickfix`, and a split
-- showing any of those is exactly where a picked file should land. With
-- oil beside Claude's pane, the empty-buftype test found no editor window,
-- the picker opened from the pane, and the file replaced Claude's buffer.
--
-- Returns whether it stepped out of a pane -- the shell or Claude's, told
-- apart from a plain :terminal by b:snacks_terminal -- so the picker can
-- rebalance the panes once a file is actually picked.
local function leave_terminal_window()
  if vim.bo.buftype ~= 'terminal' then
    return false
  end
  local from_pane = vim.b.snacks_terminal ~= nil
  local function is_editor_window(win)
    return win ~= 0
      and vim.api.nvim_win_is_valid(win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= 'terminal'
      and vim.api.nvim_win_get_config(win).zindex == nil
  end
  local target = vim.fn.win_getid(vim.fn.winnr '#')
  if not is_editor_window(target) then
    target = nil
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_editor_window(win) then
        target = win
        break
      end
    end
  end
  if target then
    vim.api.nvim_set_current_win(target)
    vim.cmd.stopinsert()
  end
  return from_pane
end

-- Give every showing pane the right half of the screen. A pane opens large --
-- the shell takes three quarters of the height, Claude three quarters of the
-- width -- because on its own it is the thing being looked at. Picking a file
-- from inside it changes that: now the file and the pane are read side by
-- side, and neither should be a sliver.
--
-- Side by side means the same shape for both panes. Claude is already a
-- vertical split -- on whichever side it was summoned to -- so it is only
-- narrowed to half the width and keeps that side. The shell opens as a bottom
-- split, and half the height there would leave the file a wide, short strip
-- above it, so the shell is moved to a full-height column on the right first
-- and then narrowed the same way. The move is Vim's own `wincmd L`,
-- run inside the pane's window, so the window and its terminal buffer are
-- untouched and Snacks keeps tracking the same window id. Whatever remains
-- goes to the editor windows.
--
-- Only one pane is ever on screen (terminal.lua), but this asks Snacks for
-- all of them rather than guessing which. The layout lasts until the pane is
-- hidden; the next toggle brings it back at its configured position and size.
local function balance_panes()
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:win_valid() then
      local position = term.opts.position
      if position == 'top' or position == 'bottom' then
        vim.api.nvim_win_call(term.win, function()
          vim.cmd.wincmd 'L'
        end)
      end
      vim.api.nvim_win_set_width(term.win, math.floor(vim.o.columns / 2))
    end
  end
end

M.leave_terminal_window = leave_terminal_window
M.balance_panes = balance_panes

return M
