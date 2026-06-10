#lang racket/base
(require redex/reduction-semantics
         "../grammar.rkt"
         "../traces/programs.rkt")

;; Every example program must be a well-formed VC program (nonterminal p).
(define-syntax-rule (check-program prog)
  (test-equal (and (redex-match VC p prog) #t) #t))

(check-program opening)
(check-program first-apply)
(check-program residuation)
(check-program if-true)
(check-program if-false)
(check-program tuple-indexing)

(test-results)
