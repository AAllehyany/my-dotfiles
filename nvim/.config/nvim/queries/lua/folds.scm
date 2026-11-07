; extends

; LuaCATS / LDoc `---` comment runs (closed on open, see lua/config/folds.lua).
((comment)+ @fold
  (#lua-match? @fold "^%-%-%-"))
