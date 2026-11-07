-- ---------- mini.nvim modules ----------
require("mini.icons").setup()
require("mini.pick").setup()
require("mini.extra").setup()
require("mini.visits").setup()

require("mini.files").setup({
  mappings = {
    close = "q",
    go_in = "l",
    go_in_plus = "<CR>",
    go_out = "h",
    go_out_plus = "H",
    mark_goto = "'",
    mark_set = "m",
    reset = "<BS>",
    reveal_cwd = "@",
    show_help = "g?",
    synchronize = "=",
    trim_left = "<",
    trim_right = ">",
  },
  options = {
    -- Safer than permanent deletion. Deleted entries go to mini.files trash.
    permanent_delete = false,

    -- Let mini.files replace netrw for directory buffers.
    use_as_default_explorer = true,

    -- LSP-aware create/delete/rename support.
    lsp_timeout = 1000,
  },
  windows = {
    preview = true,
    width_focus = 35,
    width_nofocus = 20,
    width_preview = 50,
  },
})

require("mini.bufremove").setup()
require("mini.tabline").setup()
require("mini.git").setup()

require("mini.diff").setup({
  view = {
    style = "sign",
  },
  options = {
    wrap_goto = true,
  },
})

-- mini.ai (with Tree-sitter textobjects) is set up in config/textobjects.lua.
require("mini.surround").setup()
local MiniPairs = require("mini.pairs")
MiniPairs.setup()
require("mini.comment").setup()
-- Only the bracket jumps nothing else covers. Functions, classes and arguments use ]f ]c ]a
-- (config/textobjects.lua); ]b and ]d are mapped in keymaps.lua and lsp.lua.
require("mini.bracketed").setup({
  comment    = { suffix = "/" },
  conflict   = { suffix = "x" },
  indent     = { suffix = "i" },
  location   = { suffix = "l" },
  quickfix   = { suffix = "q" },
  buffer     = { suffix = "" },
  diagnostic = { suffix = "" },
  file       = { suffix = "" },
  jump       = { suffix = "" },
  oldfile    = { suffix = "" },
  treesitter = { suffix = "" },
  undo       = { suffix = "" },
  window     = { suffix = "" },
  yank       = { suffix = "" },
})

require("mini.snippets").setup({
  mappings = {
    -- Disable global snippet expansion key.
    -- mini.completion will still use mini.snippets for LSP snippet insertion.
    expand = "",
  },
})

local MiniHipatterns = require("mini.hipatterns")
MiniHipatterns.setup({
  highlighters = {
    hex_color = MiniHipatterns.gen_highlighter.hex_color(),
  }
})
local MiniCompletion = require("mini.completion")

local function in_astro_frontmatter()
  if vim.bo.filetype ~= "astro" then
    return false
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  if vim.trim(lines[1] or "") ~= "---" then
    return false
  end

  local close_line = nil
  for i = 2, #lines do
    if vim.trim(lines[i]) == "---" then
      close_line = i
      break
    end
  end

  if close_line == nil then
    return row > 1
  end

  return row > 1 and row < close_line
end

-- ---------- Angular inline template filtering ----------
local angular_non_markup_nodes = {
  interpolation = true,
  expression = true,
  property_binding = true,
  event_binding = true,
  two_way_binding = true,
  for_declaration = true,
  if_condition = true,
  switch_expression = true,
  attribute = true,
  quoted_attribute_value = true,
  attribute_value = true,
  start_tag = true,
  self_closing_tag = true,
}

local function in_angular_template()
  if vim.bo.filetype ~= "typescript" then
    return false
  end

  -- 1. Walk the outer TypeScript tree (ignoring injections) to verify we are
  --    inside a `template: `...`` property pair.
  local ts_node = vim.treesitter.get_node({ ignore_injections = true })
  if not ts_node then
    return false
  end

  local in_template_pair = false
  local current = ts_node
  while current do
    if current:type() == "pair" then
      local key_node = current:field("key")[1]
      if key_node and vim.treesitter.get_node_text(key_node, 0) == "template" then
        in_template_pair = true
        break
      end
    end
    current = current:parent()
  end

  if not in_template_pair then
    return false
  end

  -- 2. Inspect the injected Angular tree so Emmet does NOT trigger inside
  --    {{ interpolations }}, [prop]="..." bindings, @for/@if headers, or tag attributes.
  local inj_node = vim.treesitter.get_node({ ignore_injections = false })
  while inj_node do
    if angular_non_markup_nodes[inj_node:type()] then
      return false
    end
    inj_node = inj_node:parent()
  end

  return true
end

-- ---------- Filter execution ----------
local function process_lsp_items(items, base)
  local is_astro_fm = in_astro_frontmatter()
  local is_ts_but_not_template = (vim.bo.filetype == "typescript") and not in_angular_template()

  -- Hide Emmet completions if we are in Astro frontmatter OR 
  -- if we are in a TS file but outside an Angular inline template.
  if is_astro_fm or is_ts_but_not_template then
    items = vim.tbl_filter(function(item)
      local client = item.client_id and vim.lsp.get_client_by_id(item.client_id)
      local name = client and client.name or ""

      return not name:lower():find("emmet")
    end, items)
  end

  -- Filter noisy Text items and put snippets below normal LSP items.
  return MiniCompletion.default_process_items(items, base, {
    kind_priority = {
      Text = -1,
      Snippet = 99,
    },
  })
end

MiniCompletion.setup({
  delay = {
    completion = 80,
    info = 25,
    signature = 50,
  },
  lsp_completion = {
    source_func = "omnifunc",
    auto_setup = false,
    process_items = process_lsp_items,
  },
})

-- ---------- Completion ergonomics ----------
local map = vim.keymap.set

map("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { expr = true, desc = "Completion next item" })
map("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { expr = true, desc = "Completion previous item" })

_G.ahmad_cr_action = function()
  if vim.fn.complete_info()["selected"] ~= -1 then
    return "\25" -- <C-y>
  end

  return MiniPairs.cr()
end

map("i", "<CR>", "v:lua.ahmad_cr_action()", { expr = true, desc = "Confirm completion or newline" })
