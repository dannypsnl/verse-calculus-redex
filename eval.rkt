#lang racket/base
(require redex/reduction-semantics "grammar.rkt" "rules.rkt")
(provide vc-eval run)

;; vc-->'s non-context rules fire only at a term's root; the paper applies
;; rules anywhere. compatible-closure lifts them to fire in ANY subterm of an
;; `e`, so programs under one/exists/choose actually reduce.
(define vc-eval (compatible-closure vc--> VC e))

;; run: wrap the program in one{...} (Fig 1: a program yields one result via
;; one, failing if it fails), normalize, return the value (or fail).
(define (run p)
  (define nfs (apply-reduction-relation* vc-eval (term (one ,p)) #:cache-all? #t))
  (cond
    [(null? nfs) (error 'run "no normal form (non-terminating?)")]
    [(member (term fail) nfs) (term fail)]
    [else (car nfs)]))
