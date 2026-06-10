#lang racket/base
(require redex/reduction-semantics "grammar.rkt" racket/list)
(provide fvs var< subst-ok? hnf-clash? unify-tup index-choices flat-choice seq-swap-ok?)

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

;; Total order on variables, approximating the paper's x ≺ y ("x is bound
;; inside y"). Freshly-introduced binders (α-renamed by Redex, whose printed
;; names carry a non-alphanumeric marker such as «0») are INNER binders, so
;; they sort before plain source variables — i.e. the innermost variable ends
;; up on the left of an equation, which is what keeps VAR-SWAP/SUBST from
;; ping-ponging AND lets EQN-ELIM fire. Among same-class names we fall back to
;; lexical order. (A fully faithful ≺ is binding-context-dependent; this is the
;; documented heuristic used by the implementation — see the design's known
;; soft-spot note.)
(define-metafunction VC
                     var< : x x -> boolean
                     [(var< x_1 x_2)
                      ,(let* ([s1 (symbol->string (term x_1))]
                              [s2 (symbol->string (term x_2))]
                              [f1 (regexp-match? #rx"[^a-zA-Z0-9]" s1)]
                              [f2 (regexp-match? #rx"[^a-zA-Z0-9]" s2)])
                         (cond
                           [(and f1 (not f2)) #t] ; x_1 fresh/inner, x_2 plain/outer  => x_1 < x_2
                           [(and (not f1) f2) #f] ; x_1 plain/outer, x_2 fresh/inner  => not <
                           [else (string<? s1 s2)]))])

(define-metafunction VC
                     subst-ok? : x v -> boolean
                     [(subst-ok? x_1 x_2) (var< x_1 x_2)] ; RHS is a variable y: need x < y
                     [(subst-ok? x v) #t]) ; RHS not a variable: always ok

(define-metafunction VC
                     hnf-clash? : hnf hnf -> boolean
                     [(hnf-clash? k_1 k_2) ,(not (= (term k_1) (term k_2)))]
                     [(hnf-clash? (tup v_1 ...) (tup v_2 ...))
                      ,(not (= (length (term (v_1 ...))) (length (term (v_2 ...)))))]
                     ;; Everything else clashes — per the paper's U-FAIL, which fires
                     ;; whenever U-LIT and U-TUP do not match. In particular an op or a
                     ;; lambda fails unification against anything, INCLUDING an identical
                     ;; one (add=add ⟶ fail, λ=λ ⟶ fail; paper §3.2 / §4.3): only U-LIT
                     ;; (k=k) and U-TUP (same-arity tuples) ever succeed.
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

;; right-nested value choice -> the list of its values
(define-metafunction VC
                     flat-choice : vchoice -> (v ...)
                     [(flat-choice v) (v)]
                     [(flat-choice (choose v vchoice)) (v v_1 ...)
                      (where (v_1 ...) (flat-choice vchoice))])

;; SEQ-SWAP must not fire when the left item is an equation y=v' with y <= x,
;; otherwise it would loop against SUBST/VAR-SWAP ordering.
(define-metafunction VC
                     seq-swap-ok? : eq x -> boolean
                     [(seq-swap-ok? (eqn x_1 v) x_2)
                      ,(not (or (equal? (term x_1) (term x_2)) (term (var< x_1 x_2))))] ; y<=x => not ok
                     [(seq-swap-ok? eq x) #t]) ; left item is a plain expression: ok
