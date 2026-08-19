return {
  { 'tpope/vim-surround', lazy = false },
  {
    'stevearc/conform.nvim',
    lazy = false,
    opts = {
      formatters_by_ft = {
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        json = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
      },
      format_on_save = { timeout_ms = 2000, lsp_format = 'fallback' },
    },
  },
}
