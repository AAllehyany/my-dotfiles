-- ---------- Tree-sitter textobjects ----------
-- Queries come from nvim-treesitter-textobjects; parsers from arborist.
--
-- Select (with any operator: v d c y, plus mini.ai's `an`/`il` next/last and g[ g] edges):
--   af / if   function            ac / ic   class / struct / interface
--   ao / io   block, if, loop     aa / ia   argument (mini.ai built-in)
--   au / iu   function call       ab, aq, at = brackets, quotes, tag (mini.ai built-in)
--
-- Move (normal, visual, operator-pending):
--   ]f [f  function start    ]F [F  function end
--   ]c [c  class start       ]C [C  class end
--   ]a [a  next/prev argument
--   ;  ,   repeat the last ]x / [x / f / t move forward / backward
--
-- Swap:
--   <leader>xa / <leader>xA  argument with the next / previous one
--   <leader>xf / <leader>xF  function (member) with the next / previous one

require("nvim-treesitter-textobjects").setup({
  move = { set_jumps = true },
})

local MiniAi = require("mini.ai")
local ts = MiniAi.gen_spec.treesitter

MiniAi.setup({
  n_lines = 500,
  custom_textobjects = {
    f = ts({ a = "@function.outer", i = "@function.inner" }),
    c = ts({ a = "@class.outer", i = "@class.inner" }),
    o = ts({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    u = MiniAi.gen_spec.function_call(),
  },
})

local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")
local repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

local map = vim.keymap.set
local nxo = { "n", "x", "o" }

local function moves(key, capture, name)
  local upper = key:upper()
  map(nxo, "]" .. key, function() move.goto_next_start(capture, "textobjects") end, { desc = "Next " .. name .. " start" })
  map(nxo, "[" .. key, function() move.goto_previous_start(capture, "textobjects") end, { desc = "Previous " .. name .. " start" })
  if upper ~= key then
    map(nxo, "]" .. upper, function() move.goto_next_end(capture, "textobjects") end, { desc = "Next " .. name .. " end" })
    map(nxo, "[" .. upper, function() move.goto_previous_end(capture, "textobjects") end, { desc = "Previous " .. name .. " end" })
  end
end

moves("f", "@function.outer", "function")
moves("c", "@class.outer", "class")
map(nxo, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "Next argument" })
map(nxo, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Previous argument" })

-- ; and , repeat the last move in its own direction / the opposite one, like Vim's f/t repeat.
map(nxo, ";", repeat_move.repeat_last_move, { desc = "Repeat last move" })
map(nxo, ",", repeat_move.repeat_last_move_opposite, { desc = "Repeat last move backward" })
map(nxo, "f", repeat_move.builtin_f_expr, { expr = true, desc = "Find char forward" })
map(nxo, "F", repeat_move.builtin_F_expr, { expr = true, desc = "Find char backward" })
map(nxo, "t", repeat_move.builtin_t_expr, { expr = true, desc = "Till char forward" })
map(nxo, "T", repeat_move.builtin_T_expr, { expr = true, desc = "Till char backward" })

map("n", "<leader>xa", function() swap.swap_next("@parameter.inner") end, { desc = "Swap argument with next" })
map("n", "<leader>xA", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap argument with previous" })
map("n", "<leader>xf", function() swap.swap_next("@function.outer") end, { desc = "Swap function with next" })
map("n", "<leader>xF", function() swap.swap_previous("@function.outer") end, { desc = "Swap function with previous" })
