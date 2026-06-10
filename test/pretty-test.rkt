#lang racket/base
(module+ test
  (require "../pretty.rkt" rackunit)

  (check-equal? (vc->string '3) "3")
  (check-equal? (vc->string 'x) "x")
  (check-equal? (vc->string '(app add (tup x 1))) "add⟨x, 1⟩")
  (check-equal? (vc->string '(lam x x)) "λx. x")
  (check-equal? (vc->string '(exists x (seq (eqn x (tup 2 3)) x))) "∃x. x=⟨2, 3⟩; x")
  (check-equal? (vc->string '(choose 1 2)) "1 | 2")
  (check-equal? (vc->string '(one (choose 1 2))) "one{1 | 2}")
  (check-equal? (vc->string 'fail) "fail")
  (displayln "pretty-test ok"))
