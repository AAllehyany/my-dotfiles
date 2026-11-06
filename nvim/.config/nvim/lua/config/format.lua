-- nvim/lua/config/format.lua
local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    htmlangular = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    astro = { "prettier" },
  },
  format_on_save = {
    timeout_ms = 1000,
    -- If a filetype isn't defined above (like C# or Go), 
    -- it will automatically fall back to formatting via LSP.
    lsp_format = "fallback", 
  },
})
