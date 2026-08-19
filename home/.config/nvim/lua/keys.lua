-- clear search highlights by pressing Escape
-- vim.keymap.set('n', '<Esc>', ':w<CR>', { desc = 'Save' }) -- previous: save by pressing Escape
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>:w<CR>', { desc = 'Clear Search Highlight and Save' })
-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
vim.keymap.set('n', '<leader>n', '<cmd>enew<cr>', { desc = 'New Buffer' })
vim.keymap.set('n', '<leader>x', '<cmd>bd<cr>', { desc = 'Close Buffer' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- move lines up/down (like Alt+Arrow in VSCode)
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move Line Down' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move Line Up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move Selection Down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move Selection Up' })

-- leave terminal input mode without taking Escape away from terminal programs
vim.keymap.set('t', '<C-Space>', '<C-\\><C-n>', { desc = 'Exit Terminal Mode' })
