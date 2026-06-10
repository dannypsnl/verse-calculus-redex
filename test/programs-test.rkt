#lang racket/base
(require redex/reduction-semantics
         "../grammar.rkt"
         "../metafns.rkt"
         "../traces/programs.rkt")

;; Each example is a program BODY (a closed e); one{body} is the program p
;; (Fig 1: p ::= one{e}, fvs(e)=∅). Check both: the wrapped form is a well-
;; formed p, and the body is actually closed.
(define-syntax-rule (check-program prog)
  (begin
    (test-equal (and (redex-match VC p (term (one ,prog))) #t) #t)
    (test-equal (term (fvs ,prog)) '())))

(check-program opening)
(check-program first-apply)
(check-program residuation)
(check-program if-true)
(check-program if-false)
(check-program tuple-indexing)

(test-results)
