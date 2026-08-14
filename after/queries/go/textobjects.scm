; extends

; var declaration — includes the "var" keyword
; vae: var v_name string = "value"   vie: "value"
; vae: var v_name string             vie: (nothing)
(var_declaration) @vardecl.outer

(var_declaration
  (var_spec
    value: (_) @vardecl.rhs))

; short variable declaration — x := v
(short_var_declaration
  right: (_) @vardecl.rhs) @vardecl.outer

; regular assignment — x = v
(assignment_statement
  right: (_) @vardecl.rhs) @vardecl.outer
