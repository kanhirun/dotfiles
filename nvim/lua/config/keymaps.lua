-- ================ Key Mappings ==========================

-- Clear search highlights with //
vim.keymap.set('n', '//', ':noh<CR>', { silent = true })

-- Make 0 go to first character rather than beginning of line
vim.keymap.set('n', '0', '^', { noremap = true })
vim.keymap.set('n', '^', '0', { noremap = true })

-- Move past quotes in insert mode
vim.keymap.set('i', '<C-a>', '<Esc>wa', { noremap = true })

-- ================ Universal Escape ======================
-- <C-\> drops to Normal mode from anywhere, terminal mode included.
--
-- Vim's own way out of a terminal is the two-key <C-\><C-n>; this collapses it
-- to the first key, so the chord that already starts that sequence now finishes
-- it. That also removes the usual reason to avoid <C-\> -- shadowing <C-\><C-n>
-- is the point here rather than the cost.
--
-- Deliberately NOT <Esc>: terminal programs need Esc for themselves. Claude Code
-- binds it to interrupt, and snacks routes a double-Esc to Normal mode in its own
-- terminals. Like <C-Space>'s NUL, <C-\> is a legacy control byte (0x1C), so it
-- survives terminal mode with no kitty keyboard protocol support.
--
-- Cmdline mode is left out on purpose: <Esc> already leaves it, and mapping
-- <C-\> there would shadow <C-\>e (replace the command line with an expression).
--
-- Normal mode is left out too, and claudecode.lua takes it -- "open Claude on a
-- clear composer". Escaping to Normal from Normal is the one case with nothing to
-- do: Esc there only cancels a pending count or operator, and Esc itself still
-- does that. Every mode where the escape actually matters is still here.
vim.keymap.set('t', '<C-\\>', '<C-\\><C-n>', { desc = 'Go to Normal mode' })
vim.keymap.set({ 'i', 'v', 'x', 's', 'o' }, '<C-\\>', '<Esc>', { desc = 'Go to Normal mode' })

-- Esc leaves terminal mode as well, which costs less than it looks like it should.
-- Snacks installs its own <Esc> on its terminals BUFFER-LOCALLY -- a 200ms
-- double-tap that passes a single press straight through to the program -- and
-- buffer-local beats global, so Claude's pane and the <C-Space> terminal are
-- untouched and keep Esc for interrupt. This governs plain :terminal buffers only,
-- where nothing is competing for the key.
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Go to Normal mode' })

-- ================ Custom Commands =======================
vim.api.nvim_create_user_command('Projections', 'edit .projections.json', {})
