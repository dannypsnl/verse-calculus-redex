#lang racket/base
(require redex/reduction-semantics "grammar.rkt" racket/list)
(provide fvs var< subst-ok? hnf-clash? unify-tup index-choices flat-choice seq-swap-ok?
         current-var-depths binder-depths)

(define-metafunction VC
                     fvs : any -> (x ...)
                     [(fvs x) (x)]
                     [(fvs k) ()]
                     [(fvs op) ()]
                     [(fvs fail) ()]
                     [(fvs hole) ()]
                     [(fvs (lam x e)) ,(remove* (term (x)) (term (fvs e)))]
                     [(fvs (exists x e)) ,(remove* (term (x)) (term (fvs e)))]
                     [(fvs (tup v ...)) ,(append-map (lambda (t) (term (fvs ,t))) (term (v ...)))]
                     [(fvs (app v_1 v_2)) ,(append (term (fvs v_1)) (term (fvs v_2)))]
                     [(fvs (seq eq e)) ,(append (term (fvs eq)) (term (fvs e)))]
                     [(fvs (eqn v e)) ,(append (term (fvs v)) (term (fvs e)))]
                     [(fvs (choose e_1 e_2)) ,(append (term (fvs e_1)) (term (fvs e_2)))]
                     [(fvs (one e)) (fvs e)]
                     [(fvs (all e)) (fvs e)])

;; The paper's variable order x ≺ y means "x is bound inside y" (paper §3.3:
;; var-swap fires on y=x only if x is bound inside y, so the INNERMOST-bound
;; variable ends up on the left). That order is genuinely binding-context-
;; dependent, so it cannot be decided from two bare names alone. We approximate
;; it by binder nesting depth, falling back to a name heuristic when unset.
(define current-var-depths (make-parameter #f))

;; whole-term map: bound variable name -> innermost nesting depth (1-based)
(define (binder-depths t)
  (define h (make-hash))
  (let walk ([t t] [d 0])
    (when (pair? t)
      (case (car t)
        [(exists lam)
         (define x (cadr t))
         (define d* (add1 d))
         (hash-update! h x (lambda (old) (max old d*)) d*)
         (walk (caddr t) d*)]
        [else (for-each (lambda (s) (walk s d)) (cdr t))])))
  h)

;; name-based tiebreak when depths are equal
(define (heuristic<? a b)
  (let* ([s1 (symbol->string a)]
         [s2 (symbol->string b)]
         [f1 (regexp-match? #rx"[^a-zA-Z0-9]" s1)]
         [f2 (regexp-match? #rx"[^a-zA-Z0-9]" s2)])
    (cond
      [(and f1 (not f2)) #t]
      [(and (not f1) f2) #f]
      [else (string<? s1 s2)])))

(define (var<? a b)
  (define dm (current-var-depths))
  (define da (if dm (hash-ref dm a 0) 0))
  (define db (if dm (hash-ref dm b 0) 0))
  (cond
    [(> da db) #t]
    [(< da db) #f]
    [else (heuristic<? a b)]))

(define-metafunction VC
                     var< : x x -> boolean
                     [(var< x_1 x_2) ,(var<? (term x_1) (term x_2))])

(define-metafunction VC
                     subst-ok? : x v -> boolean
                     [(subst-ok? x_1 x_2) (var< x_1 x_2)] ; RHS is a variable y: need x < y
                     [(subst-ok? x v) #t]) ; RHS not a variable: always ok

(define-metafunction VC
                     hnf-clash? : hnf hnf -> boolean
                     [(hnf-clash? k_1 k_2) ,(not (= (term k_1) (term k_2)))]
                     [(hnf-clash? (tup v_1 ...) (tup v_2 ...))
                      ,(not (= (length (term (v_1 ...))) (length (term (v_2 ...)))))]
                     ;; A lambda against ANY value — another lambda, or itself — does NOT
                     ;; clash: U-FAIL deliberately excludes it, so the equation gets STUCK
                     ;; rather than failing. Equality of functions is undecidable, so VC
                     ;; refuses to decide it (Fig 3 side condition "neither hnf1 nor hnf2
                     ;; is a lambda"; §3.2: "it gets stuck if you attempt to unify a lambda
                     ;; with any other value, including itself").
                     [(hnf-clash? (lam x e) hnf) #f]
                     [(hnf-clash? hnf (lam x e)) #f]
                     ;; Any other mismatch of non-lambda head values clashes — U-LIT (k=k)
                     ;; and U-TUP (same-arity tuples) are the only successes, so e.g. add=gt,
                     ;; add=add, and 3=⟨1⟩ all fail (Fig 3 U-FAIL fires when U-LIT/U-TUP miss).
                     [(hnf-clash? hnf_1 hnf_2) #t])

;; ⟨v_1..⟩ = ⟨v_1'..⟩ ; e   ==>   v_1 = v_1' ; ... ; e   (equal arity assumed)
(define-metafunction VC
                     unify-tup : (v ...) (v ...) e -> e
                     [(unify-tup () () e) e]
                     [(unify-tup (v_1 v_2 ...) (v_3 v_4 ...) e)
                      (seq (eqn v_1 v_3) (unify-tup (v_2 ...) (v_4 ...) e))])

;; tuple-application indexing body: (x=0; v0) | (x=1; v1) | ...
(define-metafunction VC
                     index-choices : x (v ...) k -> e
                     [(index-choices x (v) k) (seq (eqn x k) v)]
                     [(index-choices x (v_0 v_1 ...) k)
                      (choose (seq (eqn x k) v_0)
                              (index-choices x (v_1 ...) ,(add1 (term k))))])

;; flat-choice : e -> (v ...) or #f
;; Recognizes ALL-CHOICE's `v1 | ··· | vn` (Fig 3, all-choice). The paper writes
;; this as an ellipsis with no nonterminal (no `vchoice` in Fig 1/4), so we
;; encode it here in the rule machinery rather than as a grammar category.
(define-metafunction VC
                     flat-choice : e -> any
                     [(flat-choice v) (v)]
                     [(flat-choice (choose v e)) (v v_1 ...)
                      (where (v_1 ...) (flat-choice e))]
                     [(flat-choice e) #f])

;; SEQ-SWAP must not fire when the left item is an equation y=v' with y <= x,
;; otherwise it would loop against SUBST/VAR-SWAP ordering.
(define-metafunction VC
                     seq-swap-ok? : eq x -> boolean
                     [(seq-swap-ok? (eqn x_1 v) x_2)
                      ,(not (or (equal? (term x_1) (term x_2)) (term (var< x_1 x_2))))] ; y<=x => not ok
                     [(seq-swap-ok? eq x) #t]) ; left item is a plain expression: ok
