; extends

; vad on local x = v  → selects full "local x = v" (variable_declaration)
; vad on x = v        → selects "x = v" (assignment_statement)
; vid on local x = v  → selects value
; vid on local x      → selects nothing (no rhs)

; Any field assignment
(field
  name: (_)
  value: (_) @vardecl.rhs) @vardecl.outer

; Full variable declaration
(variable_declaration
  (_
    (expression_list) @vardecl.rhs)) @vardecl.outer

; Any assignment that's not a variable_declaration
((_) @_p
  (assignment_statement
    (expression_list) @vardecl.rhs) @vardecl.outer
  (#not-eq? @_p "variable_declaration"))
