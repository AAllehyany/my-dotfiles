require("arborist").setup({
  ensure_installed = {
    "angular",
    "astro",
    "scss",
  },
})

local ok, autotag = pcall(require, "nvim-ts-autotag")
if ok then
  autotag.setup({
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
    },
    aliases = {
      typescript = "html",
      htmlangular = "html",
    },
  })
end
