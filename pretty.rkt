#lang racket/base
(require racket/string racket/format)
(provide vc->string)

;; Render a core VC s-expression toward the paper's notation (best-effort,
;; for display only; no precedence minimization).
(define (vc->string t)
  (cond
    [(integer? t) (number->string t)]
    [(symbol? t) (symbol->string t)]
    [(pair? t)
     (case (car t)
       [(tup) (string-append "⟨" (string-join (map vc->string (cdr t)) ", ") "⟩")]
       [(app)
        (define f (vc->string (cadr t)))
        (define a (caddr t))
        (if (and (pair? a) (eq? (car a) 'tup))
            (string-append f (vc->string a))
            (string-append f "(" (vc->string a) ")"))]
       [(lam) (string-append "λ" (symbol->string (cadr t)) ". " (vc->string (caddr t)))]
       [(exists) (string-append "∃" (symbol->string (cadr t)) ". " (vc->string (caddr t)))]
       [(eqn) (string-append (vc->string (cadr t)) "=" (vc->string (caddr t)))]
       [(seq) (string-append (vc->string (cadr t)) "; " (vc->string (caddr t)))]
       [(choose) (string-append (vc->string (cadr t)) " | " (vc->string (caddr t)))]
       [(one) (string-append "one{" (vc->string (cadr t)) "}")]
       [(all) (string-append "all{" (vc->string (cadr t)) "}")]
       [else (format "~a" t)])]
    [else (format "~a" t)]))
