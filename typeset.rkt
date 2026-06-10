#lang racket/base
;; Paper-style typesetting of the VC grammar and the vc--> rules, via
;; redex/pict's compound and unquote rewriters. Headless: requires
;; redex/pict only — never redex/gui.
(require redex/pict pict racket/list "grammar.rkt" "rules.rkt")
(provide vc-grammar-pict vc-rules-pict vc-rules-pict/sexp with-vc-rewriters)

;; A compound rewriter receives the lws (layout words) of one parenthesized
;; form: index 0 is "(", index 1 the head symbol, 2.. the arguments, and the
;; last is ")". It returns the list of strings/lws to display instead.
(define ((infix-rw sep) lws)
  (list "" (list-ref lws 2) sep (list-ref lws 3) ""))
(define ((binder-rw prefix) lws)
  (list prefix (list-ref lws 2) ". " (list-ref lws 3) ""))
(define ((brace-rw head) lws)
  (list (string-append head "{") (list-ref lws 2) "}"))
(define (app-rw lws)
  (list "" (list-ref lws 2) " " (list-ref lws 3) ""))
(define (tup-rw lws)
  (append (list "⟨")
          (add-between (drop-right (drop lws 2) 1) ", ")
          (list "⟩")))

;; The rules escape to Racket for arithmetic, freshness and free-variable
;; checks; Redex typesets such escapes verbatim, as code on a pink
;; background. The unquote rewriter below maps each escape shape back to
;; the paper's notation instead, rendering term sub-lws through the
;; language so nonterminals keep their fonts and subscripts.
(define (op-text s) (text s (default-style) (default-font-size)))
(define (term-pict l) (lw->pict VC l))
(define (infix-pict op a b) (hbl-append (term-pict a) (op-text op) (term-pict b)))

;; An escaped call's lw-e is ("(" head arg ... ")") with spacer lws and
;; 'spring symbols interleaved; return (head-symbol arg-lw ...), else #f.
(define (call-parts l)
  (define e (lw-e l))
  (and (list? e)
       (let ([es (filter (lambda (x) (and (lw? x) (not (member (lw-e x) '("" "(" ")")))))
                         e)])
         (and (pair? es)
              (symbol? (lw-e (car es)))
              (cons (lw-e (car es)) (cdr es))))))

;; (length (term any)) → the term's lw, else #f
(define (length-arg l)
  (define p (call-parts l))
  (and p (eq? (car p) 'length) (= (length (cdr p)) 1) (cadr p)))

(define (escape->pict l)
  (define p (call-parts l))
  (define args (and p (cdr p)))
  (define (binary op) (and (= (length args) 2) (infix-pict op (car args) (cadr args))))
  (and p
       (case (car p)
         [(+) (binary " + ")]
         [(>) (binary " > ")]
         [(<=) (binary " ≤ ")]
         [(=)
          (and (= (length args) 2)
               (let ([n_1 (length-arg (car args))]
                     [n_2 (length-arg (cadr args))])
                 (if (and n_1 n_2)
                     (hbl-append (op-text "|") (term-pict n_1)
                                 (op-text "| = |") (term-pict n_2) (op-text "|"))
                     (binary " = "))))]
         [(memq) (binary " ∈ ")]
         [(variable-not-in) (op-text "fresh")]
         [(not) ; (not (equal? a b)) / (not (memq a b))
          (and (= (length args) 1)
               (let ([q (call-parts (car args))])
                 (and q (= (length (cdr q)) 2)
                      (case (car q)
                        [(equal?) (infix-pict " ≠ " (cadr q) (caddr q))]
                        [(memq) (infix-pict " ∉ " (cadr q) (caddr q))]
                        [else #f]))))]
         [else #f])))

(define (vc-unquote-rewriter l)
  (define p (escape->pict l))
  (if p
      (build-lw p (lw-line l) (lw-line-span l) (lw-column l) (lw-column-span l))
      l))

(define-syntax-rule (with-vc-rewriters body)
  (with-unquote-rewriter
    vc-unquote-rewriter
    (with-compound-rewriters
      (['seq (infix-rw "; ")]
       ['eqn (infix-rw " = ")]
       ['choose (infix-rw " | ")]
       ['exists (binder-rw "∃")]
       ['lam (binder-rw "λ")]
       ['one (brace-rw "one")]
       ['all (brace-rw "all")]
       ['app app-rw]
       ['tup tup-rw])
      body)))

;; Fig 1 (grammar), typeset toward the paper's notation.
(define (vc-grammar-pict) (with-vc-rewriters (render-language VC)))

;; Fig 3 (reduction rules), typeset toward the paper's notation.
(define (vc-rules-pict) (with-vc-rewriters (render-reduction-relation vc-->)))

;; The same rules in the model's raw s-expression notation. Terms stay
;; raw, but the Racket escapes in side conditions still read better in
;; paper notation, so the unquote rewriter applies here too.
(define (vc-rules-pict/sexp)
  (with-unquote-rewriter vc-unquote-rewriter (render-reduction-relation vc-->)))
