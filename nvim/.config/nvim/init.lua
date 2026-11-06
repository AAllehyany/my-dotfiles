vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.packages")
require("config.treesitter")
require("config.theme")
require("config.mini")
require("config.csharp").setup()
require("config.keymaps")
require("config.lsp")
require("config.format")
