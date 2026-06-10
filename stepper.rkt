#lang racket/base
(require redex/reduction-semantics
         "eval.rkt"
         "metafns.rkt"
         "pretty.rkt")
(provide step steps run trace print-steps)

;; step: one-step successors as (name . term) pairs (uses the apply-anywhere
;; relation). We bind `current-var-depths` to THIS term's binder nesting so the
;; ordering rules (VAR-SWAP/SEQ-SWAP/SUBST) orient equations innermost-on-left,
;; exactly as the paper's ≺ does — refreshed every step because reductions move
;; binders (EXI-SWAP/EXI-FLOAT). Redex memoizes metafunctions, and `var<` now
;; depends on this parameter, so caching is disabled for the duration.
(define (step t)
  (parameterize ([current-var-depths (binder-depths t)]
                 [caching-enabled? #f])
    (for/list ([nt (in-list (apply-reduction-relation/tag-with-names vc-eval t))])
      (cons (car nt) (cadr nt)))))

;; steps: greedily follow the first successor until a normal form; return it.
(define (steps t [fuel 10000])
  (let loop ([t t] [fuel fuel])
    (define ss (step t))
    (cond
      [(or (null? ss) (zero? fuel)) t]
      [else (loop (cdr (car ss)) (sub1 fuel))])))

;; print-steps: show each rewrite with its rule name, paper-style.
(define (print-steps t [fuel 10000])
  (printf "    ~a\n" (vc->string t))
  (let loop ([t t] [fuel fuel])
    (define ss (step t))
    (cond
      [(or (null? ss) (zero? fuel)) (void)]
      [else
       (define name (car (car ss)))
       (define t2 (cdr (car ss)))
       (printf "⟶{~a} ~a\n" name (vc->string t2))
       (loop t2 (sub1 fuel))])))

;; trace: open the Redex GUI on the apply-anywhere relation (requires `redex`).
(define (trace t)
  ;; Load the Redex GUI lazily — only when `trace` is actually called — so that
  ;; merely requiring this module does not pull in `racket/gui` (which fails to
  ;; initialize on a headless CI runner).
  ((dynamic-require 'redex/gui 'traces) vc-eval t))
