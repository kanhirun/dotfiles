require "wincmds"

local function moveLeft(win)
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h

  win:setFrame(f, 0.0)
end

local function moveRight(win)
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()
  
  f.x = max.x + max.w / 2 
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h

  win:setFrame(f, 0.0)
end

-- Re-sizes and moves window to the left --
hs.hotkey.bind({"cmd", "ctrl"}, "H", function()
  local win = hs.window.focusedWindow()
  moveLeft(win)
  
  for i, otherWin in ipairs(win:otherWindowsSameScreen()) do
    moveRight(otherWin)
  end
end)

-- Re-sizes and moves window to the right --
hs.hotkey.bind({"cmd", "ctrl"}, "L", function()
  local win = hs.window.focusedWindow()
  moveRight(win)
  
   for i, otherWin in ipairs(win:otherWindowsSameScreen()) do
     moveLeft(otherWin)
  end
end)

-- Expands to full screen -- 
hs.hotkey.bind({"cmd", "ctrl"}, "return", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  win:setFrame(max, 0.0)
end)
