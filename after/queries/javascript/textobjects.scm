; extends

; const / let declarations  (lexical_declaration)
; vae: const x = "foo"   vie: "foo"
; vae: let x             vie: (nothing)
(lexical_declaration) @vardecl.outer

(lexical_declaration
  (variable_declarator
    value: (_) @vardecl.rhs))

; var declarations  (variable_declaration)
; vae: var x = "foo"   vie: "foo"
; vae: var x           vie: (nothing)
(variable_declaration) @vardecl.outer

(variable_declaration
  (variable_declarator
    value: (_) @vardecl.rhs))
