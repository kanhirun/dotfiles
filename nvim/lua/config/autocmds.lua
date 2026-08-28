-- ================ zoxide integration ========================
-- Mirror every :cd into zoxide so `<C-j>` here and `j` in the shell
-- rank the same places. This covers oil's `` ` ``/`~` (actions.cd), the
-- <C-j> picker itself, and any manual :cd/:lcd/:tcd. Directory
-- navigation that does *not* change the cwd -- the <C-f> picker -- calls
-- config.zoxide.add directly.
local zoxide = vim.api.nvim_create_augroup('zoxide', { clear = true })

vim.api.nvim_create_autocmd('DirChanged', {
  group = zoxide,
  pattern = '*',
  desc = 'Record the new cwd in zoxide',
  callback = function()
    require('config.zoxide').add(vim.v.event.cwd)
  end,
})
