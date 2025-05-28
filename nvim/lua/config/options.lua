-- ================ Leader Key Configuration ===================
vim.g.mapleader = " "

-- ================ General Vim Settings ======================
vim.opt.compatible = false
vim.opt.hlsearch = false
vim.opt.backspace = "indent,eol,start"
vim.opt.history = 1000
vim.opt.showcmd = true
vim.opt.showmode = true
vim.opt.autoread = true
vim.opt.clipboard = "unnamed"
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.hidden = true

-- Enable project-level vimrc
vim.opt.exrc = true
vim.opt.secure = true

-- Folding settings
vim.opt.foldmethod = "indent"
vim.opt.foldenable = false

-- ================ UI Configuration =========================
vim.opt.guicursor = "a:blinkon0"
vim.opt.visualbell = true
vim.opt.colorcolumn = "90"

-- Persistent undo settings
if vim.fn.has('persistent_undo') == 1 and vim.fn.isdirectory(vim.fn.expand('~') .. '/.vim/backups') == 0 then
  vim.fn.system('mkdir -p ~/.vim/backups')
  vim.opt.undodir = vim.fn.expand('~/.vim/backups')
  vim.opt.undofile = true
end

vim.opt.cmdheight = 2
vim.opt.shortmess:append("c")

-- Always show the signcolumn
if vim.fn.has("patch-8.1.1564") == 1 then
  vim.opt.signcolumn = "number"
else
  vim.opt.signcolumn = "yes"
end

vim.opt.updatetime = 300

-- ================ Window Splitting Behavior ================
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ================ Python Configuration =====================
vim.g.python_host_prog = '~/.pyenv/shims/python2'
vim.g.python3_host_prog = '~/.pyenv/shims/python3'

-- ================ File Handling =========================
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- ================ Indentation ===========================
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true

-- Set autocomplete suggestion limit
vim.opt.pumheight = 5

-- Enable syntax highlighting
vim.cmd('syntax on')