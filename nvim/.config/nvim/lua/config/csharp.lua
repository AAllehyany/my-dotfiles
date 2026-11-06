local M = {}

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  return content
end

local function write_file(path, lines)
  local file = io.open(path, "w")
  if not file then
    vim.notify("Could not write C# scaffold: " .. path, vim.log.levels.ERROR)
    return false
  end

  file:write(table.concat(lines, "\n"))
  file:write("\n")
  file:close()

  return true
end

local function sanitize_identifier(value)
  value = tostring(value or "")
  value = value:gsub("[^%w_]", "_")

  if value == "" then
    return nil
  end

  if value:match("^%d") then
    value = "_" .. value
  end

  return value
end

local function sanitize_namespace(value)
  local parts = {}

  for part in tostring(value or ""):gmatch("[^%.]+") do
    local id = sanitize_identifier(part)
    if id then
      table.insert(parts, id)
    end
  end

  return table.concat(parts, ".")
end

local function normalize_path(path)
  return vim.fs.normalize(path):gsub("/+$", "")
end

local function is_build_output_path(path)
  local normalized = vim.fs.normalize(path):lower()

  return normalized:find("/bin/", 1, true)
    or normalized:find("/obj/", 1, true)
end

local function find_nearest_csproj(path)
  local start_dir = vim.fs.dirname(vim.fs.normalize(path))

  local matches = vim.fs.find(function(name)
    return name:match("%.csproj$") ~= nil
  end, {
    path = start_dir,
    upward = true,
    type = "file",
    limit = 1,
  })

  return matches[1]
end

local function relative_dir(path, root)
  path = normalize_path(path)
  root = normalize_path(root)

  if path == root then
    return ""
  end

  if vim.startswith(path, root .. "/") then
    return path:sub(#root + 2)
  end

  return ""
end

local function project_root_namespace(csproj)
  local content = read_file(csproj)

  if content then
    local root_namespace = content:match("<RootNamespace>%s*(.-)%s*</RootNamespace>")
    if root_namespace and root_namespace ~= "" then
      return sanitize_namespace(root_namespace)
    end

    local assembly_name = content:match("<AssemblyName>%s*(.-)%s*</AssemblyName>")
    if assembly_name and assembly_name ~= "" then
      return sanitize_namespace(assembly_name)
    end
  end

  return sanitize_namespace(vim.fn.fnamemodify(csproj, ":t:r"))
end

local function namespace_for_file(path)
  local csproj = find_nearest_csproj(path)
  if not csproj then
    return nil
  end

  local project_dir = vim.fs.dirname(csproj)
  local file_dir = vim.fs.dirname(vim.fs.normalize(path))

  local parts = {}
  local root_namespace = project_root_namespace(csproj)

  if root_namespace and root_namespace ~= "" then
    table.insert(parts, root_namespace)
  end

  local rel = relative_dir(file_dir, project_dir)

  for segment in rel:gmatch("[^/\\]+") do
    local id = sanitize_identifier(segment)
    if id then
      table.insert(parts, id)
    end
  end

  return table.concat(parts, ".")
end

local function file_is_empty(path)
  local content = read_file(path)

  if content == nil then
    return true
  end

  return vim.trim(content) == ""
end

local function make_template(kind, namespace, type_name)
  local lines = {}

  if namespace and namespace ~= "" then
    table.insert(lines, "namespace " .. namespace .. ";")
    table.insert(lines, "")
  end

  if kind == "class" then
    vim.list_extend(lines, {
      "public class " .. type_name,
      "{",
      "",
      "}",
    })
  elseif kind == "record" then
    vim.list_extend(lines, {
      "public record " .. type_name .. ";",
    })
  elseif kind == "interface" then
    vim.list_extend(lines, {
      "public interface " .. type_name,
      "{",
      "",
      "}",
    })
  elseif kind == "enum" then
    vim.list_extend(lines, {
      "public enum " .. type_name,
      "{",
      "",
      "}",
    })
  end

  return lines
end

function M.scaffold_file(path, opts)
  opts = opts or {}

  if not path or not path:match("%.cs$") then
    return
  end

  path = vim.fs.normalize(path)

  if is_build_output_path(path) then
    return
  end

  if not opts.force and not file_is_empty(path) then
    return
  end

  local type_name = sanitize_identifier(vim.fn.fnamemodify(path, ":t:r")) or "NewType"
  local namespace = namespace_for_file(path)

  vim.ui.select({
    "class",
    "record",
    "interface",
    "enum",
    "none",
  }, {
    prompt = "C# type for " .. vim.fn.fnamemodify(path, ":t") .. "?",
  }, function(choice)
    if not choice or choice == "none" then
      return
    end

    local lines = make_template(choice, namespace, type_name)

    if not write_file(path, lines) then
      return
    end

    local bufnr = vim.fn.bufnr(path)

    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("edit!")
      end)
    end

    vim.notify("Created C# " .. choice .. ": " .. type_name)
  end)
end

function M.scaffold_current_buffer(opts)
  opts = opts or {}

  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == "" or not path:match("%.cs$") then
    vim.notify("Current buffer is not a C# file", vim.log.levels.WARN)
    return
  end

  M.scaffold_file(path, vim.tbl_extend("force", opts, { force = true }))
end

function M.setup()
  local group = vim.api.nvim_create_augroup("AhmadCSharpScaffold", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MiniFilesActionCreate",
    callback = function(args)
      local path = args.data and args.data.to

      if not path or not path:match("%.cs$") then
        return
      end

      vim.defer_fn(function()
        M.scaffold_file(path)
      end, 250)
    end,
  })

  vim.api.nvim_create_user_command("CsScaffold", function()
    M.scaffold_current_buffer({ force = true })
  end, {
    desc = "Scaffold current C# file",
  })
end

return M
