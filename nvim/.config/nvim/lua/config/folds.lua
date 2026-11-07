-- ---------- Folding ----------
-- Tree-sitter folds everywhere. Code starts open; doc comments (///, /** */, ---, Python docstrings)
-- start closed. Doc comment folds come from queries/*/folds.scm.
--   zo / zc / za  open / close / toggle     zR / zM  open / close everything
--   <leader>zd or :FoldDocs                 close the doc comments again

local M = {}

vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldtext = "v:lua.require'config.folds'.foldtext()"
vim.opt.fillchars:append({ fold = " " })

-- ---------- doc comment detection ----------
local doc_markers = { "///", "//!", "/**", "---", '"""', "'''" }

local function doc_marker(text)
  local trimmed = text:gsub("^%s+", ""):gsub("^[rRuUbBfF]+([\"'])", "%1")
  for _, marker in ipairs(doc_markers) do
    if trimmed:sub(1, #marker) == marker then
      return marker
    end
  end
end

-- A string only counts as a docstring when it is the first statement of a module, class or function.
local function is_docstring(node)
  local parent = node:parent()
  return parent ~= nil and parent:type() == "expression_statement" and parent:prev_named_sibling() == nil
end

local function is_doc_node(node, buf)
  local kind = node:type()
  if kind:find("comment") then
    return doc_marker(vim.treesitter.get_node_text(node, buf)) ~= nil
  end
  if kind == "string" then
    return is_docstring(node) and doc_marker(vim.treesitter.get_node_text(node, buf)) ~= nil
  end
  return false
end

-- 1-based start lines of every multi-line doc comment fold in the buffer.
local function doc_fold_lines(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then
    return nil
  end
  parser:parse(true)

  local lines = {}
  parser:for_each_tree(function(tree, ltree)
    local query = vim.treesitter.query.get(ltree:lang(), "folds")
    if not query then
      return
    end
    for _, match in query:iter_matches(tree:root(), buf, 0, -1) do
      for id, nodes in pairs(match) do
        if query.captures[id] == "fold" then
          local first, last = nodes[1], nodes[#nodes]
          local start_row = first:start()
          local end_row, end_col = last:end_()
          if end_col == 0 then
            end_row = end_row - 1
          end
          if end_row > start_row and is_doc_node(first, buf) then
            lines[#lines + 1] = start_row + 1
          end
        end
      end
    end
  end)
  return lines
end

-- ---------- closing doc folds ----------
-- Tree-sitter computes folds asynchronously, so a line whose fold isn't there yet is retried briefly.
local function close_doc_folds(win, buf, tries)
  if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
    return
  end
  local lines = doc_fold_lines(buf)
  if not lines or #lines == 0 then
    return
  end

  local waiting = false
  vim.api.nvim_win_call(win, function()
    for _, lnum in ipairs(lines) do
      local starts_fold = tostring(vim.treesitter.foldexpr(lnum)):sub(1, 1) == ">"
      if starts_fold and vim.fn.foldlevel(lnum) > 0 then
        if vim.fn.foldclosed(lnum) == -1 then
          vim.cmd(lnum .. "foldclose")
        end
      else
        waiting = true
      end
    end
  end)

  if waiting and tries < 10 then
    vim.defer_fn(function() close_doc_folds(win, buf, tries + 1) end, 50)
  end
end

function M.close_docs(win)
  win = win or vim.api.nvim_get_current_win()
  close_doc_folds(win, vim.api.nvim_win_get_buf(win), 0)
end

-- Close doc folds the first time a buffer shows in a window; after that, folds are left as the user set them.
local seen = {}
local group = vim.api.nvim_create_augroup("AhmadDocFolds", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  callback = function(args)
    local win = vim.api.nvim_get_current_win()
    seen[args.buf] = seen[args.buf] or {}
    if seen[args.buf][win] then
      return
    end
    seen[args.buf][win] = true
    vim.schedule(function() close_doc_folds(win, args.buf, 0) end)
  end,
})

-- A reload (:e) resets folds, so fold the docs again; forget wiped buffers.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWipeout" }, {
  group = group,
  callback = function(args) seen[args.buf] = nil end,
})

vim.api.nvim_create_user_command("FoldDocs", function() M.close_docs() end, { desc = "Close doc comment folds" })
vim.keymap.set("n", "<leader>zd", function() M.close_docs() end, { desc = "Close doc comment folds" })

-- ---------- fold text ----------
-- Doc folds: the marker and the first line of real text. Other folds: the first line, highlighted.
local function doc_summary(buf, first, last)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, first - 1, last, false)) do
    local text = line:gsub("^%s+", "")
      :gsub("^[rRuUbBfF]*\"\"\"", ""):gsub("^[rRuUbBfF]*'''", "")
      :gsub("^///", ""):gsub("^//!", ""):gsub("^/%*%*+", ""):gsub("^%-%-%-", ""):gsub("^%*", "")
      :gsub("%*/%s*$", ""):gsub("\"\"\"%s*$", ""):gsub("'''%s*$", "")
      :gsub("<[^>]+>", "")
    text = vim.trim(text)
    if text ~= "" and not text:find("^@") then
      return text
    end
  end
  return "…"
end

local function highlighted_line(buf, lnum)
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
  local groups = {}

  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if ok and parser then
    local row = lnum - 1
    parser:for_each_tree(function(tree, ltree)
      local query = vim.treesitter.query.get(ltree:lang(), "highlights")
      if not query then
        return
      end
      for id, node in query:iter_captures(tree:root(), buf, row, row + 1) do
        local name = query.captures[id]
        if not name:find("^_") and name ~= "spell" and name ~= "nospell" then
          local sr, sc, er, ec = node:range()
          if sr < row then sc = 0 end
          if er > row then ec = #line end
          for col = sc, ec - 1 do
            groups[col] = "@" .. name .. "." .. ltree:lang()
          end
        end
      end
    end)
  end

  local chunks, text, current = {}, "", nil
  local tab = string.rep(" ", vim.bo[buf].tabstop)
  for col = 0, #line - 1 do
    local group = groups[col] or "Normal"
    if group ~= current and text ~= "" then
      chunks[#chunks + 1] = { (text:gsub("\t", tab)), current }
      text = ""
    end
    current = group
    text = text .. line:sub(col + 1, col + 1)
  end
  if text ~= "" then
    chunks[#chunks + 1] = { (text:gsub("\t", tab)), current }
  end
  return chunks
end

function M.foldtext()
  local buf = vim.api.nvim_get_current_buf()
  local first, last = vim.v.foldstart, vim.v.foldend
  local line = vim.fn.getline(first)
  local count = { "  ⋯ " .. (last - first + 1) .. " lines", "LineNr" }

  local marker = doc_marker(line)
  if marker then
    return {
      { string.rep(" ", vim.fn.indent(first)), "Normal" },
      { marker .. " " .. doc_summary(buf, first, last), "Comment" },
      count,
    }
  end

  local chunks = highlighted_line(buf, first)
  chunks[#chunks + 1] = count
  return chunks
end

return M
