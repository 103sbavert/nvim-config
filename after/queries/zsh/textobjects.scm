; extends

; zsh shares the same tree-sitter grammar structure as bash.
; See after/queries/bash/textobjects.scm for rationale.
[
  (program             (variable_assignment) @vardecl.outer)
  (compound_statement  (variable_assignment) @vardecl.outer)
  (if_statement        (variable_assignment) @vardecl.outer)
  (elif_clause         (variable_assignment) @vardecl.outer)
  (else_clause         (variable_assignment) @vardecl.outer)
  (do_group            (variable_assignment) @vardecl.outer)
  (case_item           (variable_assignment) @vardecl.outer)
  (subshell            (variable_assignment) @vardecl.outer)
]

(declaration_command) @vardecl.outer

(variable_assignment
  value: (_) @vardecl.rhs)
