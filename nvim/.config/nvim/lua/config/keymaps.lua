local map = vim.keymap.set

local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")
local MiniFiles = require("mini.files")
local MiniBufremove = require("mini.bufremove")
local MiniDiff = require("mini.diff")

-- ---------- IDEA-like jumping ----------
map("n", "<leader><leader>", function()
  MiniExtra.pickers.visit_paths({ recency_weight = 1 })
end, { desc = "Jump: recent/frequent files in project" })

map("n", "<C-p>", function()
  MiniPick.builtin.files()
end, { desc = "Find files" })

map("n", "<leader>ff", function()
  MiniPick.builtin.files()
end, { desc = "Find files" })

map("n", "<leader>fr", function()
  MiniExtra.pickers.visit_paths({ recency_weight = 1 })
end, { desc = "Recent/frequent files in cwd" })

map("n", "<leader>fR", function()
  MiniExtra.pickers.visit_paths({ cwd = "", recency_weight = 1 })
end, { desc = "Recent/frequent files (global)" })

map("n", "<leader>fo", function()
  MiniExtra.pickers.oldfiles()
end, { desc = "Old files" })

map("n", "<leader>fb", function()
  MiniPick.builtin.buffers()
end, { desc = "Buffers" })

map("n", "<leader>fg", function()
  MiniPick.builtin.grep_live()
end, { desc = "Live grep" })

map("n", "<leader>fj", function()
  MiniExtra.pickers.list({ scope = "jump" })
end, { desc = "Jump list" })

map("n", "<leader>fm", function()
  MiniExtra.pickers.marks()
end, { desc = "Marks" })

map("n", "<leader>fd", function()
  MiniExtra.pickers.diagnostic()
end, { desc = "Diagnostics" })

map("n", "<leader>fs", function()
  MiniExtra.pickers.lsp({ scope = "document_symbol" })
end, { desc = "Document symbols" })

map("n", "<leader>fS", function()
  MiniExtra.pickers.lsp({ scope = "workspace_symbol" })
end, { desc = "Workspace symbols" })

map("n", "<leader>fW", function()
  MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
end, { desc = "Workspace symbols live" })

-- ---------- file explorer ----------
local function mini_files_toggle(...)
  if not MiniFiles.close() then
    MiniFiles.open(...)
  end
end

map("n", "<leader>e", function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local path = (buf_name ~= "" and vim.uv.fs_stat(buf_name)) and buf_name or vim.fn.getcwd()
  mini_files_toggle(path)
end, { desc = "File explorer at current file" })

map("n", "<leader>E", function()
  mini_files_toggle(nil, false)
end, { desc = "File explorer at cwd" })

-- ---------- buffers ----------
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "<leader>bd", function()
  MiniBufremove.delete(0, false)
end, { desc = "Delete buffer, keep layout" })

map("n", "<leader>bD", function()
  MiniBufremove.delete(0, true)
end, { desc = "Force delete buffer" })

-- ---------- splits / windows ----------
map("n", "<leader>sv", "<C-w>v", { desc = "Vertical split" })
map("n", "<leader>sh", "<C-w>s", { desc = "Horizontal split" })
map("n", "<leader>sx", "<C-w>c", { desc = "Close split" })

map("n", "<C-h>", "<C-w>h", { desc = "Move left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move down split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move up split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move right split" })

-- ---------- idiomatic movement ----------
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up centered" })
map("n", "n", "nzzzv", { desc = "Next search centered" })
map("n", "N", "Nzzzv", { desc = "Previous search centered" })

-- ---------- Git ----------
map("n", "<leader>gg", "<cmd>Git status<cr>", { desc = "Git status" })
map("n", "<leader>gb", "<cmd>vertical Git blame -- %<cr>", { desc = "Git blame current file" })
map("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git commit" })
map("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Git push" })

map("n", "<leader>gl", function()
  MiniExtra.pickers.git_commits()
end, { desc = "Git commits" })

map("n", "<leader>gf", function()
  MiniExtra.pickers.git_files()
end, { desc = "Git files" })

map("n", "<leader>gh", function()
  MiniExtra.pickers.git_hunks()
end, { desc = "Git hunks" })

map("n", "<leader>ho", function()
  MiniDiff.toggle_overlay()
end, { desc = "Toggle diff overlay" })

-- mini.diff default hunk keys:
-- ]h / [h = next/previous hunk
-- gh      = apply/stage hunk or region
-- gH      = reset hunk or region
