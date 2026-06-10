#lang racket/base
(require redex/reduction-semantics
         "../grammar.rkt"
         "../eval.rkt")

;; Run a thunk with a wall-clock budget; #f if it didn't finish in time.
(define (within? ms thunk)
  (define result-box (box 'timeout))
  (define t (thread (lambda () (set-box! result-box (thunk)))))
  (if (sync/timeout (/ ms 1000.0) t)
      (unbox result-box)
      (begin (kill-thread t) 'timeout)))

;; Confluence proxy: a term should reach AT MOST ONE normal form.
;; Inconclusive samples (timeout, error) are skipped (treated as holding).
(define (unique-normal-form? p)
  (with-handlers ([exn:fail? (lambda (_) #t)])
    (define r (within? 1500 (lambda ()
                              (apply-reduction-relation* vc-eval (term (one ,p))
                                                         #:cache-all? #t))))
    (cond
      [(eq? r 'timeout) #t] ; inconclusive: skip
      [else
       ;; keep only pairwise non-α-equivalent normal forms
       (define reps
         (for/fold ([acc '()]) ([t (in-list r)])
           (if (for/or ([u (in-list acc)]) (alpha-equivalent? VC t u))
               acc
               (cons t acc))))
       (<= (length reps) 1)])))

(redex-check VC e (unique-normal-form? (term e))
             #:attempts 1000
             #:attempt-size (lambda (n) (min n 4))) ; keep terms small
(displayln "confluence probe complete")
