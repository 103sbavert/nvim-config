; extends

; Local variable declaration — includes type and semicolon.
; vae: string x = "foo";   vie: "foo"
; vae: int z;              vie: (nothing)
;
; C# variable_declarator has no named value field.
; The value is matched positionally: first named child is the identifier,
; second named child (if present) is the initializer expression.
(local_declaration_statement) @vardecl.outer

(local_declaration_statement
  (variable_declaration
    (variable_declarator
      (identifier)
      (_) @vardecl.rhs)))
