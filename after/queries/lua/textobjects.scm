[
  (assignment_statement
    (expression_list
      value: (_) @assignment.inner) @assignment.inner)
  (assignment_statement
    (variable_list) @assignment.inner)
]

(assignment_statement
  (variable_list) @assignment.lhs
  (expression_list) @assignment.rhs) @assignment.outer
