#lang racket/base
;; Headless reduction diagrams for the trace documents: the curated path as
;; a vertical spine, with the one-step alternatives NOT taken shown as
;; rule-name stubs computed live from the model's `step` — so "alternative
;; moves" can never drift from vc-eval. Self-drawn with pict; no redex/gui.
(require pict racket/list racket/string racket/format racket/math
         redex/reduction-semantics
         "grammar.rkt" "stepper.rkt" "pretty.rkt"
         "traces/paths.rkt")
(provide trace-pict step-pict untaken-labels)

(define PAPER-SIZE 13)
(define SEXP-SIZE 9)
(define LABEL-SIZE 10)
(define GRAY "dim gray")

;; one term in both notations: paper notation above, s-expression beneath
(define (term-pict t)
  (vl-append 1
             (text (vc->string t) 'modern PAPER-SIZE)
             (colorize (text (~s t) 'modern SEXP-SIZE) GRAY)))

(define (term-node t)
  (frame (inset (term-pict t) 6 4) #:color "gray"))

;; rule labels of the one-step successors NOT taken at node i (0-based).
;; The taken edge — (path-rule p (add1 i)) reaching (path-term p (add1 i)),
;; matched up to α-equivalence — is removed exactly once; remaining names
;; are deduplicated as "RULE ×n".
(define (untaken-labels p i)
  (define rule (path-rule p (add1 i)))
  (define next (path-term p (add1 i)))
  (define rest
    (let loop ([ss (step (path-term p i))])
      (cond
        [(null? ss) '()]
        [(and (equal? (car (car ss)) rule)
              (alpha-equivalent? VC (cdr (car ss)) next))
         (cdr ss)]
        [else (cons (car ss) (loop (cdr ss)))])))
  (define names (map car rest))
  (for/list ([n (in-list (remove-duplicates names))])
    (define c (count (lambda (m) (equal? m n)) names))
    (if (= c 1) n (format "~a ×~a" n c))))

(define (stub-pict labels)
  (if (null? labels)
      (blank)
      (colorize
        (text (string-append "↪ also legal: " (string-join labels ", "))
              'modern LABEL-SIZE)
        GRAY)))

(define (arrow-pict rule)
  (hc-append 6
             (blank 24 0)
             (vc-append -1 (vline 1 14) (arrow 7 (* -0.5 pi)))
             (text rule 'modern LABEL-SIZE)))

;; the whole curated path: nodes joined by labeled arrows, stubs alongside
(define (trace-pict p)
  (define n (path-length p))
  (when (zero? n)
    (error 'trace-pict "path ~a has no steps" (trace-path-name p)))
  (apply vl-append 2
         (append*
           (for/list ([i (in-range (add1 n))])
             (define row
               (hc-append 10
                          (term-node (path-term p i))
                          (if (< i n) (stub-pict (untaken-labels p i)) (blank))))
             (if (< i n)
                 (list row (arrow-pict (path-rule p (add1 i))))
                 (list row))))))

;; Step i (1-based, matching the documents' section numbering):
;; term_{i-1} ⟶{RULE} term_i, both notations.
(define (step-pict p i)
  (vl-append 6
             (term-pict (path-term p (sub1 i)))
             (hc-append 8
                        (text (format "⟶{~a}" (path-rule p i)) 'modern PAPER-SIZE)
                        (term-pict (path-term p i)))))
