-- ================ Key Mappings ==========================

-- Clear search highlights with //
vim.keymap.set('n', '//', ':noh<CR>', { silent = true })

-- Make 0 go to first character rather than beginning of line
vim.keymap.set('n', '0', '^', { noremap = true })
vim.keymap.set('n', '^', '0', { noremap = true })

-- Move past quotes in insert mode
vim.keymap.set('i', '<C-a>', '<Esc>wa', { noremap = true })

-- ================ Custom Commands =======================
vim.api.nvim_create_user_command('Projections', 'edit .projections.json', {})