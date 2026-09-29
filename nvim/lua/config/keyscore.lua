local M = {}

local ROWS = { '`1234567890-=', 'qwertyuiop[]\\', "asdfghjkl;'", 'zxcvbnm,./' }
local FINGERS = {
  { 'LP', 'LP', 'LR', 'LM', 'LI', 'LI', 'RI', 'RI', 'RM', 'RR', 'RP', 'RP', 'RP' },
  { 'LP', 'LR', 'LM', 'LI', 'LI', 'RI', 'RI', 'RM', 'RR', 'RP', 'RP', 'RP', 'RP' },
  { 'LP', 'LR', 'LM', 'LI', 'LI', 'RI', 'RI', 'RM', 'RR', 'RP', 'RP' },
  { 'LP', 'LR', 'LM', 'LI', 'LI', 'RI', 'RI', 'RM', 'RR', 'RP' },
}
local BASE = {
  { I = 2.2, M = 2.3, R = 2.5, P = 2.8 },
  { I = 1.3, M = 1.3, R = 1.6, P = 2.0 },
  { I = 1.0, M = 1.0, R = 1.2, P = 1.5 },
  { I = 1.4, M = 1.5, R = 1.8, P = 2.2 },
}
local STRETCH = {
  t = 0.4, g = 0.4, b = 0.4, y = 0.4, h = 0.4, n = 0.4, ['5'] = 0.4, ['6'] = 0.4,
  ['['] = 0.4, ["'"] = 0.4, ['-'] = 0.4, [']'] = 0.6, ['='] = 0.6, ['\\'] = 0.9,
}
local ORDER = { P = 1, R = 2, M = 3, I = 4 }
local SHIFTED_FROM, SHIFTED_TO = '~!@#$%^&*()_+{}|:"<>?', "`1234567890-=[]\\;',./"

M.C = {
  space = 0.8, shift = 0.6, ctrl = 0.8, alt = 0.6, ctrl_same_hand = 0.6, two_mods = 0.6,
  double = 0.3, sfb = 2.0, sfb_row = 0.5, roll_in = 0.2, roll_out = 0.5, row = 0.3,
}
local C = M.C

local POS = {}
for r, row in ipairs(ROWS) do
  for c = 1, #row do
    POS[row:sub(c, c)] = { row = r, finger = FINGERS[r][c] }
  end
end

local function stroke(ch)
  if ch == ' ' then
    return { key = ' ', hand = 'T', finger = 'T', row = 3, base = C.space, shift = false }
  end
  local shift = false
  if ch:match '%u' then
    shift, ch = true, ch:lower()
  else
    local i = SHIFTED_FROM:find(ch, 1, true)
    if i then
      shift, ch = true, SHIFTED_TO:sub(i, i)
    end
  end
  local pos = POS[ch]
  if not pos then
    return nil
  end
  return {
    key = ch,
    hand = pos.finger:sub(1, 1),
    finger = pos.finger,
    row = pos.row,
    base = BASE[pos.row][pos.finger:sub(2, 2)] + (STRETCH[ch] or 0),
    shift = shift,
  }
end

local function transition(a, b)
  if a.hand == 'T' or b.hand == 'T' then
    return 0, nil
  end
  if a.hand ~= b.hand then
    return 0, 'alternate'
  end
  local rows = math.abs(a.row - b.row)
  if a.key == b.key then
    return C.double, 'double'
  end
  if a.finger == b.finger then
    return C.sfb + C.sfb_row * rows, 'same finger'
  end
  if ORDER[b.finger:sub(2, 2)] > ORDER[a.finger:sub(2, 2)] then
    return C.roll_in + C.row * rows, 'roll in'
  end
  return C.roll_out + C.row * rows, 'roll out'
end

local NAMED = { Space = ' ', Bslash = '\\', lt = '<' }

local function parse(lhs)
  local inner = lhs:match '^<(.+)>$'
  if inner and inner:find '%-' then
    local parts = vim.split(inner, '-', { plain = true })
    local key = table.remove(parts)
    if key == '' then
      key = '-'
      table.remove(parts)
    end
    local mods = {}
    for _, m in ipairs(parts) do
      mods[m] = true
    end
    return { chord = true, mods = mods, key = NAMED[key] or key:lower() }
  end
  local chars = {}
  for i = 1, #lhs do
    chars[i] = lhs:sub(i, i)
  end
  return { chord = false, chars = chars }
end

local function count(mods)
  local n = 0
  for _ in pairs(mods) do
    n = n + 1
  end
  return n
end

function M.score(lhs)
  local p = parse(lhs)
  if p.chord then
    local s = stroke(p.key)
    if not s then
      return { beats = 1, pattern = 'unscored' }
    end
    local cost, notes = s.base, {}
    if p.mods.C then
      if s.finger == 'LP' then
        return { beats = 1, pattern = 'unreachable: the Ctrl finger' }
      end
      cost = cost + C.ctrl
      if s.hand == 'L' then
        cost = cost + C.ctrl_same_hand
        table.insert(notes, 'one hand')
      end
    end
    if p.mods.M then
      cost = cost + C.alt
    end
    if p.mods.S then
      cost = cost + C.shift
    end
    if count(p.mods) >= 2 then
      cost = cost + C.two_mods
      table.insert(notes, 'two modifiers')
    end
    return { cost = cost, beats = 1, pattern = table.concat(vim.list_extend({ 'chord' }, notes), ', ') }
  end
  local strokes = {}
  for _, ch in ipairs(p.chars) do
    local s = stroke(ch)
    if not s then
      return { beats = #p.chars, pattern = 'unscored' }
    end
    table.insert(strokes, s)
  end
  local cost, pattern = 0, {}
  for i, s in ipairs(strokes) do
    cost = cost + s.base + (s.shift and C.shift or 0)
    if i > 1 then
      local t, name = transition(strokes[i - 1], s)
      cost = cost + t
      if name then
        table.insert(pattern, name)
      end
    end
  end
  return { cost = cost, beats = #strokes, pattern = #pattern > 0 and table.concat(pattern, ', ') or 'single' }
end

function M.ideal(lhs)
  local p = parse(lhs)
  if p.chord then
    local cost = p.key == ' ' and C.space or 1.0
    cost = cost + (p.mods.C and C.ctrl or 0) + (p.mods.M and C.alt or 0) + (p.mods.S and C.shift or 0)
    return cost + (count(p.mods) >= 2 and C.two_mods or 0)
  end
  local cost = 0
  for _, ch in ipairs(p.chars) do
    local s = stroke(ch)
    cost = cost + ((s and s.hand == 'T') and C.space or 1.0) + ((s and s.shift) and C.shift or 0)
  end
  return cost
end

function M.efficiency(lhs)
  local s = M.score(lhs)
  if not s.cost then
    return 0
  end
  return math.min(1, M.ideal(lhs) / s.cost)
end

local function defined()
  local keys, seen = {}, {}
  local function take(mode, m)
    local desc = m.desc or ''
    local lhs = m.lhs:gsub(' ', '<leader>')
    local phrase = desc:find '%[.-%]' ~= nil
    local chord = lhs:match '^<[CM]%-' ~= nil and desc ~= '' and not desc:match '^:help' and not lhs:match '^<C%-W>'
    if (phrase or chord) and not lhs:match '<Plug>' and not seen[lhs] then
      seen[lhs] = true
      table.insert(keys, { lhs = lhs, desc = desc, mode = mode })
    end
  end
  local sources = { function(mode)
    return vim.api.nvim_get_keymap(mode)
  end }
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      table.insert(sources, function(mode)
        return vim.api.nvim_buf_get_keymap(buf, mode)
      end)
    end
  end
  for _, mode in ipairs { 'n', 'x', 'o', 'i', 't' } do
    for _, source in ipairs(sources) do
      for _, m in ipairs(source(mode)) do
        if mode == 'n' or mode == 'x' or mode == 'o' or m.lhs:match '^<[^>]+>$' then
          take(mode, m)
        end
      end
    end
  end
  return keys
end

function M.rows()
  local rows = {}
  for _, k in ipairs(defined()) do
    local s = M.score(k.lhs:gsub('<leader>', ' '))
    table.insert(rows, {
      lhs = k.lhs,
      desc = k.desc,
      cost = s.cost,
      beats = s.beats,
      pattern = s.pattern,
      efficiency = M.efficiency(k.lhs:gsub('<leader>', ' ')),
    })
  end
  table.sort(rows, function(a, b)
    return a.lhs < b.lhs
  end)
  return rows
end

function M.grade(rows)
  rows = rows or M.rows()
  local total = 0
  for _, r in ipairs(rows) do
    total = total + r.efficiency
  end
  return #rows > 0 and math.floor(100 * total / #rows + 0.5) or 0, #rows
end

function M.report()
  local rows = M.rows()
  local grade, n = M.grade(rows)
  local lines = { ('Key score %d / 100 across %d keys'):format(grade, n), '' }
  table.sort(rows, function(a, b)
    return a.efficiency < b.efficiency
  end)
  table.insert(lines, 'Least efficient:')
  for i = 1, math.min(10, #rows) do
    local r = rows[i]
    table.insert(lines, ('  %3d  %-14s %-30s %s'):format(math.floor(100 * r.efficiency + 0.5), r.lhs, r.pattern, r.desc))
  end
  vim.api.nvim_echo({ { table.concat(lines, '\n') } }, true, {})
end

return M
