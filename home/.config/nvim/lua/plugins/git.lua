return {
  {
    'folke/snacks.nvim',
    opts = { lazygit = {} },
    keys = { { '<leader>g', function() Snacks.lazygit() end, desc = 'LazyGit' } },
  },
}
