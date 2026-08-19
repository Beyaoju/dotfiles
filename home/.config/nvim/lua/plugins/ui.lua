return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'catppuccin-nvim',
        globalstatus = true,
      },
      sections = {
        lualine_c = {
          { 'filename', path = 1, shorting_target = 0 },
        },
      },
    },
  },
  {
    'folke/which-key.nvim',
    lazy = false,
    config = true,  -- popup that shows what my leader keys do
  },
}
