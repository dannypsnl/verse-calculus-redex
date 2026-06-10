#lang racket/base
(require "../stepper.rkt" redex/reduction-semantics rackunit)

;; step returns a list of (name . term) pairs for the one-step successors
(define ss (step (term (app add (tup 3 4)))))
(check-not-false (member '("APP-ADD" . 7) ss)) ; APP-ADD produces 7

;; steps drives to a value, returning the final term
(check-equal? (steps (term (app add (tup 3 4)))) 7)
(displayln "stepper-test ok")
