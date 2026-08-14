; extends

; const / let declarations — type annotations are transparent to the value: field
; vae: const x: string = "foo"   vie: "foo"
; vae: let x: boolean            vie: (nothing)
(lexical_declaration) @vardecl.outer

(lexical_declaration
  (variable_declarator
    value: (_) @vardecl.rhs))

; var declarations
(variable_declaration) @vardecl.outer

(variable_declaration
  (variable_declarator
    value: (_) @vardecl.rhs))
