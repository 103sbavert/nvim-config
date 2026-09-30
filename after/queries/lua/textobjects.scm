; extends

(table_constructor
  (field
    name: (_)
    value: (_) @assignment.rhs) @assignment.outer
  ","? @assignment.outer)
