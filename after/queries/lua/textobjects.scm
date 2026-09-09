[
  (assignment_statement
    (expression_list
      value: (_) @assignment.inner) @assignment.inner)
  (assignment_statement
    (variable_list) @assignment.inner)
]

((_)
  (assignment_statement
    (variable_list) @assignment.lhs
    (expression_list) @assignment.rhs) @assignment.outer)

(field
  name: (_)
  value: (_) @assignment.rhs) @assignment.outer
