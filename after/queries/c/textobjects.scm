; extends

; Variable declaration — covers initialized and uninitialized forms.
; vae: int x = 5;   vie: 5
; vae: int x;       vie: (nothing — no init_declarator)
(declaration) @vardecl.outer

(declaration
  declarator: (init_declarator
    value: (_) @vardecl.rhs))
