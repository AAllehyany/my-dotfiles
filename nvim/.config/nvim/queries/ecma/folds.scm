; extends

; JSDoc / TSDoc blocks (closed on open, see lua/config/folds.lua). Inherited by typescript, javascript and tsx.
((comment) @fold
  (#lua-match? @fold "^/%*%*"))
