; extends

; outer : the declaration, excluding any leading attribute_list(s) for properties.
; rhs   : the initializer/value (fields, locals) or value/accessors (properties).
;
; Local: whole node.
(local_declaration_statement (variable_declaration)) @assignment.outer

; Field: span modifiers (or variable_declaration, when absent) .. variable_declaration,
; so leading attribute_list(s) are excluded.
(field_declaration
  (modifier)* @assignment.outer
  (variable_declaration) @assignment.outer)

; Property: span modifier (or type, when absent) .. value/accessors, so leading
; attribute_list(s) are excluded from the selection.
(property_declaration
  (modifier)* @assignment.outer
  type: (_) @assignment.outer
  [
    value: (_)
    accessors: (_)
  ] @assignment.outer)

; rhs for fields + locals: the initializer value.
(variable_declaration
  (variable_declarator
    (identifier)
    (_) @assignment.rhs))

; rhs for properties: the value or the accessors.
(property_declaration
  [
    value: (_)
    accessors: (_)
  ] @assignment.rhs)

; Plain re-assignment to an existing variable.
(assignment_expression) @assignment.outer

(assignment_expression
  right: (_) @assignment.rhs)
