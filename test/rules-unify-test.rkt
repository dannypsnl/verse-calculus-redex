#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

;; U-LIT: 3=3; e -> e   (and 3=4; e -> fail via U-FAIL)
(test--> vc--> (term (seq (eqn 3 3) x)) (term x)) ; U-LIT
(test--> vc--> (term (seq (eqn 3 4) x)) (term fail)) ; U-FAIL
;; U-TUP: ⟨a,b⟩=⟨1,2⟩; e -> a=1; b=2; e
(test--> vc--> (term (seq (eqn (tup a b) (tup 1 2)) done))
         (term (seq (eqn a 1) (seq (eqn b 2) done)))) ; U-TUP
;; U-FAIL: tuple vs int
(test--> vc--> (term (seq (eqn (tup 1) 5) done)) (term fail)) ; U-FAIL
;; U-FAIL: an op fails unification against anything, INCLUDING an identical op
;; (paper §3.2: U-FAIL fires whenever U-LIT/U-TUP don't match; only k=k and
;; same-arity tuples ever succeed). Regression for hnf-clash? on equal ops.
(test--> vc--> (term (seq (eqn add add) done)) (term fail)) ; U-FAIL (add=add)
(test--> vc--> (term (seq (eqn add gt) done)) (term fail)) ; U-FAIL (add=gt)
;; U-FAIL: a lambda fails unification against itself, too (paper §4.3)
(test--> vc--> (term (seq (eqn (lam x x) (lam x x)) done)) (term fail)) ; U-FAIL (λ=λ)
;; U-OCCURS: x = ⟨x⟩; e -> fail
(test--> vc--> (term (seq (eqn x (tup x)) done)) (term fail)) ; U-OCCURS
;; SUBST: x = 5 ; x  -->  x = 5 ; 5   (occurrence in continuation replaced)
(test-->> vc--> (term (seq (eqn x 5) x)) (term (seq (eqn x 5) 5))) ; SUBST
(test-results)
