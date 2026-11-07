; extends

; Doc comments fold as one block (closed on open, see lua/config/folds.lua).
((comment)+ @fold
  (#lua-match? @fold "^///"))

((comment) @fold
  (#lua-match? @fold "^/%*%*"))
