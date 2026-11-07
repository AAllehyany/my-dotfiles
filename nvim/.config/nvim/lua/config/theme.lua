
-- ============================================================
-- BLACKOUT
-- Black / Graphite / Silver / Cold Steel / Blood Red
-- ============================================================

vim.o.termguicolors = true
vim.o.background = "dark"

local blackout = {
  -- Backgrounds
  bg       = "#050505",
  bg2      = "#0c0d0f",
  surface  = "#17191b",
  surface2 = "#303238",

  -- Foregrounds
  fg       = "#dce0e4",
  white    = "#ffffff",
  silver   = "#b5bac0",
  muted    = "#8d959f",
  dim      = "#62676e",

  -- Restrained accents
  red      = "#a64b50",
  red2     = "#c56b70",
  steel    = "#98adbf",
  blue     = "#71889b",
}

local function apply_blackout()
  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  vim.o.pumblend = 0
  vim.o.winblend = 0

  -- ==========================================================
  -- MAIN EDITOR
  -- Transparent so Kitty's black background shows through
  -- ==========================================================

  hi("Normal", {
    fg = blackout.fg,
    bg = "NONE",
  })

  hi("NormalNC", {
    fg = blackout.fg,
    bg = "NONE",
  })

  hi("SignColumn", {
    fg = blackout.muted,
    bg = "NONE",
  })

  hi("FoldColumn", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("Folded", {
    fg = blackout.muted,
    bg = "NONE",
  })

  hi("LineNr", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("LineNrAbove", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("LineNrBelow", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("CursorLineNr", {
    fg = blackout.white,
    bg = blackout.surface,
    bold = true,
  })

  hi("EndOfBuffer", {
    fg = blackout.bg,
    bg = "NONE",
  })

  -- ==========================================================
  -- WINDOW CHROME
  -- ==========================================================

  hi("StatusLine", {
    fg = blackout.silver,
    bg = "NONE",
  })

  hi("StatusLineNC", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("TabLine", {
    fg = blackout.muted,
    bg = "NONE",
  })

  hi("TabLineFill", {
    bg = "NONE",
  })

  hi("TabLineSel", {
    fg = blackout.white,
    bg = "NONE",
    bold = true,
  })

  hi("WinSeparator", {
    fg = blackout.surface2,
    bg = "NONE",
  })

  hi("VertSplit", {
    fg = blackout.surface2,
    bg = "NONE",
  })

  hi("WinBar", {
    fg = blackout.fg,
    bg = "NONE",
  })

  hi("WinBarNC", {
    fg = blackout.muted,
    bg = "NONE",
  })

  -- ==========================================================
  -- CURSOR / SELECTION / SEARCH
  -- ==========================================================

  hi("CursorLine", {
    bg = blackout.surface,
  })

  hi("CursorColumn", {
    bg = blackout.surface,
  })

  hi("Visual", {
    bg = blackout.surface2,
  })

  hi("Search", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  hi("IncSearch", {
    fg = blackout.bg,
    bg = blackout.silver,
    bold = true,
  })

  hi("CurSearch", {
    fg = blackout.bg,
    bg = blackout.white,
    bold = true,
  })

  hi("MatchParen", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  -- ==========================================================
  -- SYNTAX
  -- Neutral syntax instead of Gruvbox's warm palette
  -- ==========================================================

  hi("Comment", {
    fg = blackout.dim,
    italic = true,
  })

  hi("Constant", {
    fg = blackout.silver,
  })

  hi("String", {
    fg = blackout.silver,
  })

  hi("Character", {
    fg = blackout.silver,
  })

  hi("Number", {
    fg = blackout.steel,
  })

  hi("Boolean", {
    fg = blackout.steel,
  })

  hi("Float", {
    fg = blackout.steel,
  })

  hi("Identifier", {
    fg = blackout.fg,
  })

  hi("Function", {
    fg = blackout.white,
  })

  hi("Statement", {
    fg = blackout.silver,
  })

  hi("Conditional", {
    fg = blackout.white,
    bold = true,
  })

  hi("Repeat", {
    fg = blackout.white,
  })

  hi("Operator", {
    fg = blackout.muted,
  })

  hi("Keyword", {
    fg = blackout.white,
  })

  hi("Exception", {
    fg = blackout.red2,
  })

  hi("PreProc", {
    fg = blackout.muted,
  })

  hi("Type", {
    fg = blackout.steel,
  })

  hi("StorageClass", {
    fg = blackout.silver,
  })

  hi("Structure", {
    fg = blackout.steel,
  })

  hi("Typedef", {
    fg = blackout.steel,
  })

  hi("Special", {
    fg = blackout.silver,
  })

  hi("Delimiter", {
    fg = blackout.muted,
  })

  hi("Error", {
    fg = blackout.red2,
    bold = true,
  })

  hi("Todo", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  -- ==========================================================
  -- TREESITTER
  -- Explicit captures to prevent unwanted colors
  -- ==========================================================

  local captures = {
    ["@comment"]            = "Comment",
    ["@comment.documentation"] = "Comment",
    ["@constant"]           = "Constant",
    ["@constant.builtin"]   = "Constant",
    ["@string"]             = "String",
    ["@string.special"]     = "String",
    ["@character"]          = "Character",
    ["@number"]             = "Number",
    ["@number.float"]       = "Float",
    ["@boolean"]            = "Boolean",
    ["@variable"]           = "Identifier",
    ["@variable.builtin"]   = "Identifier",
    ["@variable.parameter"] = "Identifier",
    ["@property"]           = "Identifier",
    ["@function"]           = "Function",
    ["@function.call"]      = "Function",
    ["@function.builtin"]   = "Function",
    ["@function.method"]    = "Function",
    ["@function.method.call"] = "Function",
    ["@constructor"]        = "Function",
    ["@keyword"]            = "Keyword",
    ["@keyword.function"]   = "Keyword",
    ["@keyword.return"]     = "Keyword",
    ["@keyword.operator"]   = "Operator",
    ["@keyword.conditional"] = "Conditional",
    ["@keyword.repeat"]     = "Repeat",
    ["@keyword.exception"]  = "Exception",
    ["@operator"]           = "Operator",
    ["@type"]               = "Type",
    ["@type.builtin"]       = "Type",
    ["@type.definition"]    = "Type",
    ["@punctuation.bracket"] = "Delimiter",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.special"] = "Special",
    ["@tag"]                = "Keyword",
    ["@tag.attribute"]      = "Identifier",
    ["@tag.delimiter"]      = "Delimiter",
    ["@markup.heading"]     = "Function",
    ["@markup.strong"]      = "Function",
    ["@markup.italic"]      = "Comment",
    ["@markup.link"]        = "Type",
  }

  for capture, target in pairs(captures) do
    hi(capture, { link = target })
  end

  -- LSP semantic token overrides
  local semantic = {
    ["@lsp.type.class"]     = "Type",
    ["@lsp.type.decorator"] = "Function",
    ["@lsp.type.enum"]      = "Type",
    ["@lsp.type.enumMember"] = "Constant",
    ["@lsp.type.function"]  = "Function",
    ["@lsp.type.interface"] = "Type",
    ["@lsp.type.macro"]     = "PreProc",
    ["@lsp.type.method"]    = "Function",
    ["@lsp.type.namespace"] = "Identifier",
    ["@lsp.type.number"]    = "Number",
    ["@lsp.type.parameter"] = "Identifier",
    ["@lsp.type.property"]  = "Identifier",
    ["@lsp.type.string"]    = "String",
    ["@lsp.type.struct"]    = "Type",
    ["@lsp.type.type"]      = "Type",
    ["@lsp.type.typeParameter"] = "Type",
    ["@lsp.type.variable"]  = "Identifier",
  }

  for capture, target in pairs(semantic) do
    hi(capture, { link = target })
  end

  -- ==========================================================
  -- FLOATING WINDOWS
  -- Opaque, almost-black surfaces
  -- ==========================================================

  hi("NormalFloat", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  hi("FloatBorder", {
    fg = blackout.surface2,
    bg = blackout.bg2,
  })

  hi("FloatTitle", {
    fg = blackout.white,
    bg = blackout.bg2,
    bold = true,
  })

  hi("FloatFooter", {
    fg = blackout.muted,
    bg = blackout.bg2,
  })

  -- ==========================================================
  -- NATIVE COMPLETION / MINI.COMPLETION
  -- ==========================================================

  hi("Pmenu", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  hi("PmenuSel", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  hi("PmenuKind", {
    fg = blackout.steel,
    bg = blackout.bg2,
  })

  hi("PmenuKindSel", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  hi("PmenuExtra", {
    fg = blackout.muted,
    bg = blackout.bg2,
  })

  hi("PmenuExtraSel", {
    fg = blackout.white,
    bg = blackout.surface2,
  })

  hi("PmenuMatch", {
    fg = blackout.white,
    bold = true,
  })

  hi("PmenuMatchSel", {
    fg = blackout.white,
    bold = true,
  })

  hi("PmenuSbar", {
    bg = blackout.surface,
  })

  hi("PmenuThumb", {
    bg = blackout.muted,
  })

  hi("WildMenu", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  -- ==========================================================
  -- DIAGNOSTICS
  -- Red = errors
  -- Steel = warnings and information
  -- Gray = hints
  -- ==========================================================

  hi("DiagnosticError", {
    fg = blackout.red2,
  })

  hi("DiagnosticWarn", {
    fg = blackout.steel,
  })

  hi("DiagnosticInfo", {
    fg = blackout.silver,
  })

  hi("DiagnosticHint", {
    fg = blackout.muted,
  })

  hi("DiagnosticOk", {
    fg = blackout.steel,
  })

  hi("DiagnosticUnderlineError", {
    undercurl = true,
    sp = blackout.red,
  })

  hi("DiagnosticUnderlineWarn", {
    undercurl = true,
    sp = blackout.steel,
  })

  hi("DiagnosticFloatingError", {
    fg = blackout.red2,
    bg = blackout.bg2,
  })

  hi("DiagnosticFloatingWarn", {
    fg = blackout.steel,
    bg = blackout.bg2,
  })

  hi("DiagnosticFloatingInfo", {
    fg = blackout.silver,
    bg = blackout.bg2,
  })

  hi("DiagnosticFloatingHint", {
    fg = blackout.muted,
    bg = blackout.bg2,
  })

  -- ==========================================================
  -- MINI.PICK
  -- ==========================================================

  hi("MiniPickNormal", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  hi("MiniPickBorder", {
    fg = blackout.surface2,
    bg = blackout.bg2,
  })

  hi("MiniPickBorderBusy", {
    fg = blackout.red,
    bg = blackout.bg2,
  })

  hi("MiniPickBorderText", {
    fg = blackout.white,
    bg = blackout.bg2,
    bold = true,
  })

  hi("MiniPickHeader", {
    fg = blackout.silver,
    bg = blackout.bg2,
  })

  hi("MiniPickPrompt", {
    fg = blackout.white,
    bg = blackout.bg2,
    bold = true,
  })

  hi("MiniPickPromptCaret", {
    fg = blackout.bg,
    bg = blackout.white,
  })

  hi("MiniPickMatchCurrent", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  hi("MiniPickMatchMarked", {
    fg = blackout.steel,
    bg = blackout.bg2,
    bold = true,
  })

  hi("MiniPickMatchRanges", {
    fg = blackout.white,
    bg = blackout.bg2,
    bold = true,
  })

  hi("MiniPickPreviewLine", {
    bg = blackout.surface,
  })

  hi("MiniPickPreviewRegion", {
    bg = blackout.surface2,
  })

  hi("MiniPickIconDirectory", {
    fg = blackout.steel,
    bg = blackout.bg2,
  })

  hi("MiniPickIconFile", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  -- ==========================================================
  -- MINI.FILES
  -- ==========================================================

  hi("MiniFilesNormal", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  hi("MiniFilesBorder", {
    fg = blackout.surface2,
    bg = blackout.bg2,
  })

  hi("MiniFilesBorderModified", {
    fg = blackout.red2,
    bg = blackout.bg2,
  })

  hi("MiniFilesTitle", {
    fg = blackout.muted,
    bg = blackout.bg2,
  })

  hi("MiniFilesTitleFocused", {
    fg = blackout.white,
    bg = blackout.bg2,
    bold = true,
  })

  hi("MiniFilesCursorLine", {
    bg = blackout.surface,
  })

  hi("MiniFilesDirectory", {
    fg = blackout.steel,
    bg = blackout.bg2,
  })

  hi("MiniFilesFile", {
    fg = blackout.fg,
    bg = blackout.bg2,
  })

  -- ==========================================================
  -- MINI.TABLINE
  -- Transparent, minimalist
  -- ==========================================================

  hi("MiniTablineCurrent", {
    fg = blackout.white,
    bg = "NONE",
    bold = true,
  })

  hi("MiniTablineVisible", {
    fg = blackout.silver,
    bg = "NONE",
  })

  hi("MiniTablineHidden", {
    fg = blackout.dim,
    bg = "NONE",
  })

  hi("MiniTablineModifiedCurrent", {
    fg = blackout.red2,
    bg = "NONE",
    bold = true,
  })

  hi("MiniTablineModifiedVisible", {
    fg = blackout.red2,
    bg = "NONE",
  })

  hi("MiniTablineModifiedHidden", {
    fg = blackout.red,
    bg = "NONE",
  })

  hi("MiniTablineFill", {
    bg = "NONE",
  })

  hi("MiniTablineTabpagesection", {
    fg = blackout.bg,
    bg = blackout.silver,
    bold = true,
  })

  -- ==========================================================
  -- DIFF
  -- ==========================================================

  hi("DiffAdd", {
    fg = blackout.steel,
    bg = blackout.surface,
  })

  hi("DiffChange", {
    fg = blackout.silver,
    bg = blackout.surface,
  })

  hi("DiffDelete", {
    fg = blackout.red2,
    bg = blackout.surface,
  })

  hi("DiffText", {
    fg = blackout.white,
    bg = blackout.surface2,
    bold = true,
  })

  hi("Added", {
    fg = blackout.steel,
  })

  hi("Changed", {
    fg = blackout.silver,
  })

  hi("Removed", {
    fg = blackout.red2,
  })
end

-- Start with a clean slate instead of Gruvbox.
vim.cmd("highlight clear")

if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "blackout"

apply_blackout()

-- Reapply after UI startup or any colorscheme changes.
local blackout_group = vim.api.nvim_create_augroup(
  "BlackoutHighlights",
  { clear = true }
)

vim.api.nvim_create_autocmd({
  "ColorScheme",
  "VimEnter",
  "UIEnter",
}, {
  group = blackout_group,
  callback = function()
    vim.schedule(apply_blackout)
  end,
})
