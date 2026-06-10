#lang racket/base
(module+ test
  (require redex/reduction-semantics
           "../grammar.rkt"
           "../metafns.rkt"
           rackunit)

  ;; unify-tup: expand ⟨v1..⟩=⟨v1'..⟩; e into a chain of element equations
  (check-equal? (term (unify-tup (1 2) (3 4) done))
                (term (seq (eqn 1 3) (seq (eqn 2 4) done))))
  (check-equal? (term (unify-tup () () done)) (term done))

  ;; index-choices: ⟨v0,v1⟩ indexing expansion body (starting index 0)
  (check-equal? (term (index-choices x (a b) 0))
                (term (choose (seq (eqn x 0) a) (seq (eqn x 1) b))))
  (check-equal? (term (index-choices x (a) 0))
                (term (seq (eqn x 0) a)))

  ;; flat-choice: right-nested value choice -> list of values
  (check-equal? (term (flat-choice (choose 1 (choose 2 3)))) (term (1 2 3)))
  (check-equal? (term (flat-choice 7)) (term (7)))
  (displayln "build-test ok"))
