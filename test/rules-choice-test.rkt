#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

(test--> vc--> (term (one fail)) (term fail)) ; ONE-FAIL
(test--> vc--> (term (one 5)) (term 5)) ; ONE-VALUE
(test--> vc--> (term (one (choose 5 9))) (term 5)) ; ONE-CHOICE
(test--> vc--> (term (all fail)) (term (tup))) ; ALL-FAIL
(test--> vc--> (term (all 5)) (term (tup 5))) ; ALL-VALUE
(test--> vc--> (term (all (choose 1 (choose 2 3)))) (term (tup 1 2 3))) ; ALL-CHOICE
(test--> vc--> (term (choose fail 5)) (term 5)) ; CHOOSE-R
(test--> vc--> (term (choose 5 fail)) (term 5)) ; CHOOSE-L
(test--> vc--> (term (choose (choose 1 2) 3))
         (term (choose 1 (choose 2 3)))) ; CHOOSE-ASSOC
;; CHOOSE: float a choice out of a non-empty choice context, under one{}
(test--> vc--> (term (one (seq z (choose 1 2))))
         (term (one (choose (seq z 1) (seq z 2))))) ; CHOOSE
(test-results)
