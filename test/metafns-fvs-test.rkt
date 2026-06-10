#lang racket/base
(module+ test
  (require redex/reduction-semantics
           "../grammar.rkt"
           "../metafns.rkt"
           rackunit
           racket/set)

  (define (fvs-set t) (list->seteq (term (fvs ,t))))

  (check-equal? (fvs-set (term x)) (seteq 'x))
  (check-equal? (fvs-set (term 3)) (seteq))
  (check-equal? (fvs-set (term add)) (seteq))
  (check-equal? (fvs-set (term (app add (tup x y)))) (seteq 'x 'y))
  (check-equal? (fvs-set (term (lam x (app add (tup x y))))) (seteq 'y)) ; x bound
  (check-equal? (fvs-set (term (exists x (seq (eqn x y) x)))) (seteq 'y)) ; x bound
  (check-equal? (fvs-set (term (choose x (one y)))) (seteq 'x 'y))
  (displayln "fvs-test ok"))
