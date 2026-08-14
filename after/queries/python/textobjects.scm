; extends

; Assignment — covers plain, type-annotated, and annotation-only forms:
;   x = "foo"      vae: x = "foo"    vie: "foo"
;   x: int = 42    vae: x: int = 42  vie: 42
;   x: bool        vae: x: bool      vie: (nothing — right field absent)
(assignment) @vardecl.outer

(assignment
  right: (_) @vardecl.rhs)
