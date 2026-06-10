#lang racket/base
(module+ test
  (require rackunit "../traces/trace-lib.rkt")

  ;; must-step: success returns the expected (curated) term
  (check-equal? (must-step '(app add (tup 3 4)) "APP-ADD" 7) 7)

  ;; success is judged up to α-equivalence: the machine may pick other
  ;; bound names; the curated spelling is returned, not the machine's
  (check-equal?
   (must-step '(exists a (seq (eqn a 1) a))
              "SUBST"
              '(exists b (seq (eqn b 1) 1)))
   '(exists b (seq (eqn b 1) 1)))

  ;; wrong rule name: error listing actual successors
  (check-exn #rx"no successor"
             (lambda () (must-step '(app add (tup 3 4)) "APP-GT" 7)))

  ;; right rule, wrong result term: same error
  (check-exn #rx"no successor"
             (lambda () (must-step '(app add (tup 3 4)) "APP-ADD" 8)))

  ;; must-be-stuck: a value has no successors; returns the term
  (check-equal? (must-be-stuck 7) 7)

  ;; a reducible term is not stuck
  (check-exn #rx"still reduces"
             (lambda () (must-be-stuck '(app add (tup 3 4))))))
