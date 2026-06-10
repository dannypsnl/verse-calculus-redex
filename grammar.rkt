#lang racket/base
(require redex/reduction-semantics)
(provide VC)

(define-language VC
                 ;; ---- Fig 1: terms ----
                 (k ::= integer) ; integer constants
                 (op ::= add gt) ; primops
                 (hnf ::= k op (tup v ...) (lam x e)) ; head values
                 (v ::= x hnf) ; values (a variable is a value)
                 (eq ::= e (eqn v e)) ; expression-or-equation: e | v=e
                 (e ::= v
                    (app v v) ; application v1 v2
                    (seq eq e) ; eq ; e
                    (exists x e) ; ∃x. e
                    fail
                    (choose e e) ; e1 | e2
                    (one e) ; one{e}
                    (all e)) ; all{e}
                 (p ::= (one e)) ; program: one{e}, e closed (Fig 1)
                 (x y z f g ::= variable-not-otherwise-mentioned)

                 ;; ---- Fig 4: contexts ----
                 (X ::= hole (seq (eqn v X) e) (seq X e) (seq eq X)) ; execution
                 (V ::= hole (tup v ... V v ...)) ; value
                 (SX ::= (one SC) (all SC)) ; scope
                 (SC ::= hole (choose e SC) (choose SC e)) ; Fig 4: □ | SC e | e SC (choice nav only; seq/∃/eqn nav is CX's job)
                 (CX ::= hole (seq (eqn v CX) e) (seq CX e) (seq ceq CX) (exists x CX)) ; choice
                 (ce ::= v (seq ceq ce) (one e) (all e) (exists x ce) (app op v)) ; choice-free
                 (ceq ::= ce (eqn v ce))

                 #:binding-forms
                 (lam x e #:refers-to x)
                 (exists x e #:refers-to x))
