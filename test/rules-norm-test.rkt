#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

(define-syntax-rule (test-->a rel t ...)
  (test--> rel #:equiv (λ (a b) (alpha-equivalent? VC a b)) t ...))

;; SEQ-ASSOC: (eq ; e1) ; e2 -> eq ; (e1 ; e2)
(test--> vc--> (term (seq (seq (eqn x 1) a) b))
         (term (seq (eqn x 1) (seq a b)))) ; SEQ-ASSOC
;; EQN-FLOAT: v = (eq ; e1) ; e2 -> eq ; (v = e1) ; e2
(test--> vc--> (term (seq (eqn y (seq (eqn x 1) a)) b))
         (term (seq (eqn x 1) (seq (eqn y a) b)))) ; EQN-FLOAT
;; EXI-SWAP: ∃x.∃y. e -> ∃y.∃x. e
;; NOTE: this term also reduces by EXI-ELIM (x,y both unused), so test--> sees
;; BOTH reducts; we list both. The EXI-SWAP reduct is matched up to α.
(test-->a vc--> (term (exists x (exists y z)))
          (term (exists y (exists x z))) ; EXI-SWAP
          (term (exists y z))) ; EXI-ELIM (co-fires)
;; EXI-FLOAT: X[∃x. e] -> ∃x. X[e]   when X /= hole and x not free in X
(test-->a vc--> (term (seq (exists x x) done))
          (term (exists x (seq x done)))) ; EXI-FLOAT (α)
(test-results)
