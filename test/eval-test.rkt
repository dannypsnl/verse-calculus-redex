#lang racket/base
(require redex/reduction-semantics
         "../eval.rkt")

;; The paper's opening example (§1):
;;   ∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y   reduces to   2
(define prog
  (term (exists x (exists y (exists z
                                    (seq (eqn x (tup y 3)) (seq (eqn x (tup 2 z)) y)))))))

(test-equal (run prog) (term 2))

;; choice + one at the program level: one{ 7 | 5 } = 7
(test-equal (run (term (choose 7 5))) (term 7))

;; failure: ∃x. x=fail; 33  ->  fail  ->  program fails
(test-equal (run (term (exists x (seq (eqn x fail) 33)))) (term fail))
(test-results)
