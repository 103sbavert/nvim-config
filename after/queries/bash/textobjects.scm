; extends

; Bare variable assignment — x="foo"
; Parent context limits matching to direct children of known container nodes,
; ensuring no overlap with declaration_command captures below.
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

; Declaration commands: local / declare / export / readonly / typeset x=v
; Includes the keyword in the outer selection.
(declaration_command) @vardecl.outer

; Value — works for both bare and decorated assignments since
; variable_assignment (and its value field) exists in both cases.
(variable_assignment
  value: (_) @vardecl.rhs)
