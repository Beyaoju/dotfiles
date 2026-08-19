local o = vim.opt
vim.g.mapleader = ' '          -- space is the leader key
o.expandtab = true             -- spaces, not tabs
o.shiftwidth = 2               -- 2 spaces per indent level
o.number = true                -- absolute number on the cursor line, relative elsewhere
o.relativenumber = true        -- relative line numbers for fast jumps
o.ignorecase = true            -- search is case-insensitive by default
o.smartcase = true             -- case-sensitive only if i type a capital
o.clipboard = 'unnamedplus'    -- share the system clipboard
o.scrolloff = 16               -- keep cursor away from the screen edge
o.undofile = true              -- persistent undo across sessions
o.mouse = ''                   -- no mouse in nvim; also lets Herdr keep host mouse capture off so Escape isn't swallowed
o.autoread = true              -- reload files changed by external tools

local autosave_group = vim.api.nvim_create_augroup('autosave', { clear = true })

vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'FocusLost' }, {
  group = autosave_group,
  callback = function(args)
    local buf = args.buf

    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local buffer = vim.bo[buf]
    local is_file = buffer.buftype == '' and vim.api.nvim_buf_get_name(buf) ~= ''

    if is_file and buffer.modified and buffer.modifiable and not buffer.readonly then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent update')
      end)
    end
  end,
  desc = 'Auto-save changed files',
})

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  command = 'checktime',
  desc = 'Reload files changed outside Neovim',
})

vim.api.nvim_create_autocmd('FileChangedShell', {
  callback = function()
    vim.v.fcs_choice = 'reload'
  end,
  desc = 'Always prefer externally changed files',
})

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    source = 'if_many',
  },
  underline = true,
  signs = true,
  severity_sort = true,
})
