#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

;; VAL-ELIM: v ; e -> e
(test--> vc--> (term (seq 7 done)) (term done)) ; VAL-ELIM
;; EXI-ELIM: ∃x. e -> e  when x not free in e
(test--> vc--> (term (exists x 5)) (term 5)) ; EXI-ELIM
;; EQN-ELIM: ∃x. (x = 5 ; done) -> done   (x not free elsewhere)
(test--> vc--> (term (exists x (seq (eqn x 5) done))) (term done)) ; EQN-ELIM
;; FAIL-ELIM: X[fail] -> fail  when X /= hole
(test--> vc--> (term (seq fail done)) (term fail)) ; FAIL-ELIM
(test-results)
