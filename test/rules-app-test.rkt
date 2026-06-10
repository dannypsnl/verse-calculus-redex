#lang racket/base
(require redex/reduction-semantics "../grammar.rkt" "../rules.rkt")

;; Compare reduction results up to α-equivalence (VC declares #:binding-forms),
;; so the fresh binders introduced by APP-BETA/APP-TUP match the names used in
;; the expected terms regardless of which fresh name Redex actually chose.
(define-syntax-rule (test-->a rel from to)
  (test--> rel #:equiv (λ (a b) (alpha-equivalent? VC a b)) from to))

(test-->a vc--> (term (app add (tup 3 4))) (term 7)) ; APP-ADD
(test-->a vc--> (term (app gt (tup 4 3))) (term 4)) ; APP-GT
(test-->a vc--> (term (app gt (tup 3 4))) (term fail)) ; APP-GT-FAIL
(test-->a vc--> (term (app gt (tup 3 3))) (term fail)) ; APP-GT-FAIL (<=)
;; APP-BETA (compared up to α): (λx.x)(7) -> ∃x. x=7; x
(test-->a vc--> (term (app (lam x x) 7))
          (term (exists x (seq (eqn x 7) x))))
;; APP-TUP: ⟨10,20⟩(z) -> ∃w. w=z; (w=0;10)|(w=1;20)
(test-->a vc--> (term (app (tup 10 20) z))
          (term (exists w (seq (eqn w z)
                               (choose (seq (eqn w 0) 10) (seq (eqn w 1) 20))))))
;; APP-TUP-0
(test-->a vc--> (term (app (tup) z)) (term fail))
(test-results)
