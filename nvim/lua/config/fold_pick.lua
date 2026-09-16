-- Labels foldable treesitter nodes in the window, flash-style, and folds what
-- you pick. "Foldable" is whatever the language's folds.scm captures as
-- @fold: functions, blocks, if/for, literals, and so on.
--
-- Two pickers share the machinery. "node" gives each node its own label and
-- folds that one node. "level" gives every node at the same nesting depth
-- the same digit, and folds all of them at once.
local M = {}

---@class FoldPick.Candidate
---@field first number  first line of the fold
---@field last number   last line of the fold
---@field col number    column the label sits at
---@field depth number  how many other foldable nodes enclose it, buffer-wide

-- Every foldable node in the buffer, with its depth. Buffer-wide for two
-- reasons: depth stays the same however far you have scrolled into a
-- function, and the level picker folds a level across the whole file, not
-- just the part of it in view.
---@return FoldPick.Candidate[]
function M.all_candidates(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not (ok and parser) then
    return {}
  end
  parser:parse(true)
  local all, seen = {}, {} ---@type FoldPick.Candidate[], table<string, boolean>
  parser:for_each_tree(function(tstree, tree)
    local query = tstree and vim.treesitter.query.get(tree:lang(), "folds")
    if not query then
      return
    end
    for id, node in query:iter_captures(tstree:root(), buf) do
      if query.captures[id] == "fold" then
        local sr, sc, er, ec = node:range()
        -- A node that ends at column 0 finishes on the previous line.
        if ec == 0 then
          er = er - 1
        end
        local first, last = sr + 1, er + 1
        local key = first .. ":" .. last
        -- One-line nodes hide nothing.
        if last > first and not seen[key] then
          seen[key] = true
          all[#all + 1] = { first = first, last = last, col = sc, depth = 0 }
        end
      end
    end
  end)

  for _, c in ipairs(all) do
    for _, o in ipairs(all) do
      if o ~= c and o.first <= c.first and o.last >= c.last then
        c.depth = c.depth + 1
      end
    end
  end
  return all
end

-- The candidates whose start line is on screen in the window: the ones that
-- can carry a label.
---@return FoldPick.Candidate[]
function M.candidates(win)
  -- line() treats winid 0 as "no such window", not "current window".
  win = win == 0 and vim.api.nvim_get_current_win() or win
  local all = M.all_candidates(vim.api.nvim_win_get_buf(win))
  local top, bot = vim.fn.line("w0", win), vim.fn.line("w$", win)

  local out = {} ---@type FoldPick.Candidate[]
  vim.api.nvim_win_call(win, function()
    for _, c in ipairs(all) do
      local closed = vim.fn.foldclosed(c.first)
      -- A start line inside a closed fold is invisible, unless it is that
      -- fold's own start line.
      if c.first >= top and c.first <= bot and (closed == -1 or closed == c.first) then
        out[#out + 1] = c
      end
    end
  end)
  return out
end

local function to_match(win, it, label)
  local Pos = require("flash.search.pos")
  return {
    win = win,
    pos = Pos({ it.first, it.col }),
    end_pos = Pos({ it.first, it.col }),
    label = label,
    highlight = false,
    fold_last = it.last,
    fold_depth = it.depth,
  }
end

-- Closest candidates to the cursor take the first labels, as flash does.
local function match_nodes(win, state)
  local labels = state:labels()
  local cur = vim.api.nvim_win_get_cursor(win)[1]
  local items = M.candidates(win)
  table.sort(items, function(a, b)
    local da, db = math.abs(a.first - cur), math.abs(b.first - cur)
    return da == db and a.first < b.first or da < db
  end)
  local ret = {}
  for _, it in ipairs(items) do
    local label = table.remove(labels, 1)
    if not label then
      break
    end
    ret[#ret + 1] = to_match(win, it, label)
  end
  return ret
end

-- Every node at depth N carries label N+1, so the digit reads as the level.
local function match_levels(win, state)
  local labels = state:labels()
  local ret = {}
  for _, it in ipairs(M.candidates(win)) do
    local label = labels[it.depth + 1]
    if label then
      ret[#ret + 1] = to_match(win, it, label)
    end
  end
  return ret
end

---@param how "toggle"|"open"|"close"
local function fold_lines(first, last, how)
  local closed = vim.fn.foldclosed(first) == first
  if how == "toggle" then
    how = closed and "open" or "close"
  end
  if how == "open" then
    if closed then
      vim.cmd(("%dfoldopen"):format(first))
    end
  elseif vim.fn.foldlevel(first) > vim.fn.foldlevel(first - 1) and vim.fn.foldlevel(last) > vim.fn.foldlevel(last + 1) then
    -- A fold already spans these lines; close it rather than nesting a twin.
    vim.cmd(("%dfoldclose"):format(first))
  else
    vim.cmd(("%d,%dfold"):format(first, last))
    -- :fold normally leaves the new fold closed. Only close it if it did not,
    -- since an unconditional foldclose would close the enclosing fold too.
    if vim.fn.foldclosed(first) ~= first then
      vim.cmd(("%dfoldclose"):format(first))
    end
  end
end

local function in_win(win, fn)
  vim.api.nvim_win_call(win, function()
    if vim.wo.foldmethod ~= "manual" then
      vim.notify("foldmethod is " .. vim.wo.foldmethod .. "; fold_pick needs manual", vim.log.levels.WARN)
      return
    end
    vim.wo.foldenable = true
    fn()
  end)
end

---@param match {win:number, pos:number[], fold_last:number}
function M.fold(match)
  in_win(match.win, function()
    fold_lines(match.pos[1], match.fold_last, "toggle")
  end)
end

-- Folds every node in the buffer at the picked label's depth, not only the
-- ones that were on screen to be labelled. All the visible ones closed
-- already means open the level; anything else means close it, so one press
-- never leaves a level half-folded. Only the visible ones vote because a node
-- hidden inside a closed ancestor cannot report its own state.
function M.fold_level(match, state)
  local group = {}
  for _, c in ipairs(M.all_candidates(vim.api.nvim_win_get_buf(match.win))) do
    if c.depth == match.fold_depth then
      group[#group + 1] = c
    end
  end
  in_win(match.win, function()
    local all_closed = true
    for _, m in ipairs(state.results) do
      if m.label == match.label and vim.fn.foldclosed(m.pos[1]) ~= m.pos[1] then
        all_closed = false
        break
      end
    end
    local how = all_closed and "open" or "close"

    -- Innermost first: closing an outer fold hides the inner start lines,
    -- and :fold on a hidden line would attach to the wrong fold.
    table.sort(group, function(a, b)
      return a.first > b.first
    end)

    -- An Ex range that falls inside a closed fold is silently widened to the
    -- whole fold, so a node hidden under a closed ancestor cannot be folded
    -- or opened in place. Each closed ancestor is opened first and noted;
    -- they are all closed again afterwards, innermost first, since closing an
    -- outer one would hide the line the inner one is closed by.
    local reopened = {}
    for _, c in ipairs(group) do
      while true do
        local closed = vim.fn.foldclosed(c.first)
        if closed == -1 or closed == c.first then
          break
        end
        vim.cmd(("%dfoldopen"):format(closed))
        reopened[#reopened + 1] = closed
      end
      fold_lines(c.first, c.last, how)
    end
    for i = #reopened, 1, -1 do
      vim.cmd(("%dfoldclose"):format(reopened[i]))
    end
  end)
end

local modes = {
  node = { matcher = match_nodes, action = M.fold },
  level = { matcher = match_levels, action = M.fold_level, labels = "123456789" },
}

-- Opens the picker without reading keys, so callers (and tests) can inspect
-- the labelled state. pick() is open() plus the key loop.
---@param mode? "node"|"level"
function M.open(mode)
  local Config = require("flash.config")
  local Repeat = require("flash.repeat")
  local m = modes[mode or "node"]
  return Repeat.get_state(
    "fold_pick_" .. (mode or "node"),
    Config.get({
      matcher = m.matcher,
      labeler = function() end,
      action = m.action,
      labels = m.labels,
      -- max_length = 0: every key is a label, none is a search character.
      search = { multi_window = false, max_length = 0, incremental = false },
      -- inline: the label is inserted ahead of the node's first keyword rather
      -- than painted over the character before it, which at column 0 is the
      -- previous line.
      label = { before = true, after = false, style = "inline", uppercase = false },
      prompt = { enabled = false },
    })
  )
end

---@param mode? "node"|"level"
function M.pick(mode)
  M.open(mode):loop({
    jump_on_max_length = false,
    abort = function()
      require("flash.util").exit()
    end,
  })
end

return M
