#lang racket/base
(require redex/reduction-semantics
         "../grammar.rkt"
         "../stepper.rkt"
         "../pretty.rkt")
(provide must-step must-be-stuck)

;; Format a successor list for error messages.
(define (successors->string ss)
  (apply string-append
         (for/list ([s (in-list ss)])
           (format "\n  ⟶{~a} ~a" (car s) (vc->string (cdr s))))))

;; must-step: verify (rule . expected) is a legal vc-eval successor of t,
;; up to α-equivalence. Returns `expected` — the curated spelling, NOT the
;; machine's α-renamed term — so clean variable names chain into the next
;; step. On failure, lists the actual successors so the document is easy to
;; repair when rules change.
(define (must-step t rule expected)
  (define ss (step t))
  (if (for/or ([s (in-list ss)])
        (and (equal? (car s) rule)
             (alpha-equivalent? VC (cdr s) expected)))
      expected
      (error 'must-step
             "no successor of\n    ~a\nmatches ⟶{~a} ~a\nactual successors:~a"
             (vc->string t) rule (vc->string expected)
             (successors->string ss))))

;; must-be-stuck: verify t is a vc-eval normal form; returns t.
(define (must-be-stuck t)
  (define ss (step t))
  (unless (null? ss)
    (error 'must-be-stuck "term still reduces:\n    ~a~a"
           (vc->string t) (successors->string ss)))
  t)
