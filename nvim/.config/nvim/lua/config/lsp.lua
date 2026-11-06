-- ---------- LSP ----------
local map = vim.keymap.set
local MiniCompletion = require("mini.completion")
local MiniExtra = require("mini.extra")

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  MiniCompletion.get_lsp_capabilities()
)

vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})

vim.lsp.config("vtsls", {
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
    },
  },
})

-- ---------- Angular Language Server ----------
local function resolve_ngserver_bin()
  local exe = vim.fn.exepath("ngserver")
  if exe ~= "" and exe:find("mise/shims", 1, true) then
    local out = vim.fn.systemlist({ "mise", "which", "ngserver" })
    if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
      return out[1]
    end
  end
  return exe ~= "" and exe or "ngserver"
end

local function collect_angular_probes(root_dir)
  local fs, uv = vim.fs, vim.uv
  local ts_probes = {}
  local ng_probes = {}
  local seen_ts = {}
  local seen_ng = {}

  local function add_ts(p)
    if p and not seen_ts[p] and uv.fs_stat(p) then
      seen_ts[p] = true
      table.insert(ts_probes, p)
    end
  end

  local function add_ng(p)
    if p and not seen_ng[p] and uv.fs_stat(p) then
      seen_ng[p] = true
      table.insert(ng_probes, p)
    end
  end

  -- 1. Project-local node_modules (supports pnpm/npm @angular/language-service)
  if root_dir then
    local project_nm = fs.joinpath(root_dir, "node_modules")
    add_ts(project_nm)
    add_ng(project_nm)
    add_ng(fs.joinpath(project_nm, "@angular/language-server/node_modules"))
  end

  -- 2. Global node_modules from resolved ngserver binary
  local ngserver_bin = resolve_ngserver_bin()
  local realpath = uv.fs_realpath(ngserver_bin) or ngserver_bin
  if realpath and realpath ~= "" then
    local global_nm = fs.normalize(fs.joinpath(fs.dirname(realpath), "../../.."))
    add_ts(global_nm)
    add_ng(fs.joinpath(global_nm, "@angular/language-server/node_modules"))
    add_ng(global_nm)
  end

  return table.concat(ts_probes, ","), table.concat(ng_probes, ",")
end

local function get_angular_core_version(root_dir)
  if not root_dir then
    return ""
  end
  local package_json = vim.fs.joinpath(root_dir, "package.json")
  if not vim.uv.fs_stat(package_json) then
    return ""
  end
  local ok, content = pcall(vim.fn.readblob, package_json)
  if not ok or not content then
    return ""
  end
  local ok_json, json = pcall(vim.json.decode, content)
  if not ok_json or type(json) ~= "table" then
    return ""
  end
  local version = (json.dependencies or {})["@angular/core"]
    or (json.devDependencies or {})["@angular/core"]
    or ""
  return version:match("%d+%.%d+%.%d+") or ""
end

vim.lsp.config("angularls", {
  cmd = function(dispatchers, config)
    local root_dir = (config and config.root_dir) or vim.fn.getcwd()
    local ts_probe, ng_probe = collect_angular_probes(root_dir)
    local cmd = {
      resolve_ngserver_bin(),
      "--stdio",
      "--tsProbeLocations",
      ts_probe,
      "--ngProbeLocations",
      ng_probe,
      "--angularCoreVersion",
      get_angular_core_version(root_dir),
    }
    return vim.lsp.rpc.start(cmd, dispatchers)
  end,
  filetypes = { "typescript", "html", "typescriptreact", "htmlangular" },
  root_markers = { "angular.json", "nx.json", "project.json" },
})

vim.lsp.config("astro", {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = {
    "package.json",
    "astro.config.mjs",
    "astro.config.ts",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
  init_options = {
    typescript = {},
  },
})

vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

vim.lsp.config("tailwindcss", {
  filetypes = {
    "astro",
    "html",
    "htmlangular",
    "css",
    "scss",
    "sass",
    "less",
    "postcss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "mdx",
  },
  settings = {
    tailwindCSS = {
      validate = true,
      classAttributes = {
        "class",
        "className",
        "class:list",
        "classList",
        "ngClass",
      },
      includeLanguages = {
        astro = "html",
        htmlangular = "html",
        typescriptreact = "html",
        javascriptreact = "html",
      },
      lint = {
        cssConflict = "warning",
        invalidApply = "error",
        invalidScreen = "error",
        invalidVariant = "error",
        invalidConfigPath = "error",
        invalidTailwindDirective = "error",
        recommendedVariantOrder = "warning",
      },
    },
  },
})

vim.lsp.config("emmet_language_server", {
  cmd = { "emmet-language-server", "--stdio" },
  filetypes = {
    "astro",
    "html",
    "htmlangular",
    "css",
    "scss",
    "sass",
    "less",
    "javascriptreact",
    "typescriptreact",
    "typescript",
  },
  root_markers = {
    "package.json",
    ".git",
  },
  init_options = {
    showAbbreviationSuggestions = true,

    -- emmet-language-server supports "always" or "never".
    -- Keep "always" so Emmet still works in Astro/Angular markup;
    -- our completion filter hides it outside templates/markup.
    showExpandedAbbreviation = "always",

    -- Important: don't make Emmet items snippet-priority items.
    showSuggestionsAsSnippets = false,

    includeLanguages = {
      astro = "html",
      javascriptreact = "html",
      typescriptreact = "html",
      htmlangular = "html",
      typescript = "html",
    },
  },
})

-- Only enable LSP servers whose binaries are actually installed
local server_binaries = {
  kotlin_lsp = "kotlin-lsp",
  gopls = "gopls",
  vtsls = "vtsls",
  pyright = "pyright-langserver",
  astro = "astro-ls",
  emmet_language_server = "emmet-language-server",
  tailwindcss = "tailwindcss-language-server",
  angularls = "ngserver",
}

local servers_to_enable = { "roslyn_ls" }
for server, bin in pairs(server_binaries) do
  if vim.fn.executable(bin) == 1 then
    table.insert(servers_to_enable, server)
  end
end

vim.lsp.enable(servers_to_enable)

-- ---------- Smart LSP Navigation & Angular Helpers ----------
local function dedupe_lsp_items(items, same_line_dedupe)
  local seen = {}
  local result = {}
  for _, item in ipairs(items) do
    local file = vim.fs.normalize(item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)) or "")
    local lnum = item.lnum or 1
    local col = same_line_dedupe and 0 or (item.col or 1)
    local key = string.format("%s:%d:%d", file, lnum, col)
    if not seen[key] then
      seen[key] = true
      table.insert(result, item)
    end
  end
  return result
end

local function jump_to_item(item)
  vim.cmd("normal! m'")
  local target_file = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr))
  if target_file and target_file ~= "" then
    local cur_file = vim.api.nvim_buf_get_name(0)
    if vim.fs.normalize(target_file) ~= vim.fs.normalize(cur_file) then
      vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.fnamemodify(target_file, ":.")))
    end
  elseif item.bufnr and vim.api.nvim_buf_is_valid(item.bufnr) then
    vim.api.nvim_set_current_buf(item.bufnr)
  end
  local line_count = vim.api.nvim_buf_line_count(0)
  local lnum = math.min(math.max(item.lnum or 1, 1), line_count)
  local col = math.max((item.col or 1) - 1, 0)
  vim.api.nvim_win_set_cursor(0, { lnum, col })
  vim.cmd("normal! zvzz")
end

local function smart_lsp_nav(scope, jump_if_single)
  local orig = vim.lsp.buf[scope]
  vim.lsp.buf[scope] = function(arg1, arg2)
    local opts = (scope == "references") and arg2 or arg1
    opts = opts or {}
    local orig_on_list = opts.on_list
    opts.on_list = function(data)
      data.items = dedupe_lsp_items(data.items or {}, scope ~= "references")
      if #data.items == 0 then
        vim.notify("No LSP " .. scope .. " found", vim.log.levels.INFO)
        return
      end
      if jump_if_single and #data.items == 1 then
        jump_to_item(data.items[1])
        return
      end
      if orig_on_list then
        return orig_on_list(data)
      end
    end
    if scope == "references" then
      return orig(arg1, opts)
    else
      return orig(opts)
    end
  end
  local ok, err = pcall(MiniExtra.pickers.lsp, { scope = scope })
  vim.lsp.buf[scope] = orig
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

local function find_angular_sections(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "typescript")
  if not ok or not parser then
    return nil, nil
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return nil, nil
  end
  local root = trees[1]:root()
  local template_node = nil
  local class_body_node = nil

  local function walk(node)
    local ntype = node:type()
    if ntype == "pair" and not template_node then
      local key_node = node:field("key")[1]
      local val_node = node:field("value")[1]
      if key_node and val_node and vim.treesitter.get_node_text(key_node, bufnr) == "template" then
        template_node = val_node
      end
    elseif ntype == "class_body" and not class_body_node then
      class_body_node = node
    end
    for child in node:iter_children() do
      if template_node and class_body_node then
        return
      end
      walk(child)
    end
  end

  walk(root)
  return template_node, class_body_node
end

local function pos_in_node(pos, node)
  if not node then
    return false
  end
  local sr, sc, er, ec = node:range()
  local r, c = pos[1] - 1, pos[2]
  if r < sr or r > er then
    return false
  end
  if r == sr and c < sc then
    return false
  end
  if r == er and c > ec then
    return false
  end
  return true
end

local function angular_toggle_template_class()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name:match("%.html$") then
    local ts_file = buf_name:gsub("%.html$", ".ts")
    if vim.uv.fs_stat(ts_file) then
      vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.fnamemodify(ts_file, ":.")))
      return
    end
  elseif buf_name:match("%.ts$") and not buf_name:match("%.spec%.ts$") then
    local html_file = buf_name:gsub("%.ts$", ".html")
    if vim.uv.fs_stat(html_file) then
      vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.fnamemodify(html_file, ":.")))
      return
    end
  end

  local template_node, class_body_node = find_angular_sections(0)
  if not template_node or not class_body_node then
    vim.notify("No inline Angular @Component template/class found in buffer", vim.log.levels.INFO)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! m'")

  if pos_in_node(cursor, template_node) then
    vim.b.ng_last_template_pos = cursor
    local target = vim.b.ng_last_class_pos
    if not (target and pos_in_node(target, class_body_node)) then
      local sr, sc, er = class_body_node:range()
      local target_line = math.min(sr + 2, er + 1)
      local line_text = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1] or ""
      local indent = #(line_text:match("^%s*") or "")
      target = { target_line, math.max(indent, sc) }
    end
    vim.api.nvim_win_set_cursor(0, target)
    vim.cmd("normal! zvzz")
  else
    if pos_in_node(cursor, class_body_node) then
      vim.b.ng_last_class_pos = cursor
    end
    local target = vim.b.ng_last_template_pos
    if not (target and pos_in_node(target, template_node)) then
      local sr, sc, er = template_node:range()
      local target_line = (er > sr) and (sr + 2) or (sr + 1)
      local line_text = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1] or ""
      local indent = #(line_text:match("^%s*") or "")
      target = { target_line, (er > sr) and indent or (sc + 1) }
    end
    vim.api.nvim_win_set_cursor(0, target)
    vim.cmd("normal! zvzz")
  end
end

local function angular_toggle_spec()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    return
  end
  local target
  if buf_name:match("%.spec%.ts$") then
    target = buf_name:gsub("%.spec%.ts$", ".ts")
  elseif buf_name:match("%.ts$") then
    target = buf_name:gsub("%.ts$", ".spec.ts")
  elseif buf_name:match("%.html$") then
    target = buf_name:gsub("%.html$", ".spec.ts")
  end

  if target and vim.uv.fs_stat(target) then
    vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.fnamemodify(target, ":.")))
  elseif target then
    vim.notify("Companion file not found: " .. vim.fn.fnamemodify(target, ":."), vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }

    vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"

    local function lmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
    end

    -- g = go / code navigation: jump directly on 1 result, open MiniPick on multiple.
    lmap("n", "gd", function()
      smart_lsp_nav("definition", true)
    end, "Go to definition")

    lmap("n", "gD", function()
      smart_lsp_nav("declaration", true)
    end, "Go to declaration")

    lmap("n", "gr", function()
      smart_lsp_nav("references", false)
    end, "Find references/usages")

    lmap("n", "gi", function()
      smart_lsp_nav("implementation", true)
    end, "Find implementations")

    lmap("n", "gy", function()
      smart_lsp_nav("type_definition", true)
    end, "Go to type definition")

    -- Angular component navigation shortcuts
    local ft = vim.bo[ev.buf].filetype
    if ft == "typescript" or ft == "html" or ft == "htmlangular" then
      lmap("n", "<leader>at", angular_toggle_template_class, "Angular: toggle template / class")
      lmap("n", "ga", angular_toggle_template_class, "Angular: toggle template / class")
      lmap("n", "<leader>as", angular_toggle_spec, "Angular: toggle .ts / .spec.ts")
    end

    -- docs
    lmap("n", "K", vim.lsp.buf.hover, "Hover documentation")

    -- <leader>l = LSP actions
    lmap("n", "<leader>lr", vim.lsp.buf.rename, "LSP rename")
    lmap({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP code action")

    lmap("n", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "LSP format")

    lmap("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")

    lmap("n", "<leader>ls", function()
      MiniExtra.pickers.lsp({ scope = "document_symbol" })
    end, "Document symbols")

    lmap("n", "<leader>lS", function()
      MiniExtra.pickers.lsp({ scope = "workspace_symbol" })
    end, "Workspace symbols")

    lmap("n", "<leader>lW", function()
      MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
    end, "Workspace symbols live")

    -- diagnostics navigation
    lmap("n", "[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, "Previous diagnostic")

    lmap("n", "]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })

      lmap("n", "<leader>lh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
      end, "Toggle inlay hints")
    end
  end,
})
