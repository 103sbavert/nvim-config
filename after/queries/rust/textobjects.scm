; extends

; let declaration — covers all forms: plain, typed, mutable.
; vae: let x = "foo";       vie: "foo"
; vae: let mut x: i32 = 5;  vie: 5
; vae: let z: bool;         vie: (nothing — value field absent)
(let_declaration) @vardecl.outer

(let_declaration
  value: (_) @vardecl.rhs)
