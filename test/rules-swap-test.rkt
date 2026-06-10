#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

;; HNF-SWAP: 3 = x ; e -> x = 3 ; e
(test--> vc--> (term (seq (eqn 3 x) done)) (term (seq (eqn x 3) done))) ; HNF-SWAP
;; VAR-SWAP: b = a ; e -> a = b ; e   (fires only when a < b)
(test--> vc--> (term (seq (eqn b a) done)) (term (seq (eqn a b) done))) ; VAR-SWAP
;; VAR-SWAP must NOT fire the other way (a = b with a<b stays):
(test-equal (member (term (seq (eqn b a) done))
                    (apply-reduction-relation vc--> (term (seq (eqn a b) done))))
            #f)
;; SEQ-SWAP: (e ; x=v ; e2) -> (x=v ; e ; e2) when e is not a y=v' with y<=x.
;; Use a plain-expression head so the swap is unambiguous:
(test--> vc--> (term (seq (one 9) (seq (eqn x 1) done)))
         (term (seq (eqn x 1) (seq (one 9) done)))) ; SEQ-SWAP
(test-results)
