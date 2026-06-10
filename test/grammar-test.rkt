#lang racket/base
(module+ test
  (require redex/reduction-semantics
           "../grammar.rkt"
           rackunit)

  ;; well-formed terms
  (check-true (redex-match? VC e (term 3)))
  (check-true (redex-match? VC e (term x)))
  (check-true (redex-match? VC e (term (app add (tup 3 4)))))
  (check-true (redex-match? VC e (term (lam x (app add (tup x 1))))))
  (check-true (redex-match? VC e (term (exists x (seq (eqn x (tup 2 3)) x)))))
  (check-true (redex-match? VC e (term (choose 1 (choose 2 3)))))
  (check-true (redex-match? VC e (term (one (choose 1 2)))))
  (check-true (redex-match? VC e (term (all fail))))

  ;; an equation may only sit in the eq-slot of a seq, never standalone as e
  (check-false (redex-match? VC e (term (eqn x 3))))
  ;; literal keywords are not variables
  (check-false (redex-match? VC x (term add)))

  ;; Fig 4 contexts. A scope context SC navigates only through choice (SC e | e SC)
  ;; and the hole; seq/∃/eqn navigation is CX's job. So SC must NOT match a
  ;; sequence context like □; e (regression: an extra (seq SC e) production would
  ;; let CHOOSE take partial-lift steps the paper does not have).
  (check-true  (redex-match? VC SC (term hole)))
  (check-true  (redex-match? VC SC (term (choose hole done))))
  (check-true  (redex-match? VC SC (term (choose done hole))))
  (check-false (redex-match? VC SC (term (seq hole done))))
  (displayln "grammar-test ok"))
