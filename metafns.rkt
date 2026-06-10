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
;; dependent, so it cannot be decided from two bare names alone.
;;
;; `binder-depths` recovers it from the whole term: each ∃/λ-bound variable
;; gets its nesting depth (the outermost binder is 1, deeper binders are
;; larger; for a shadowed name we keep the innermost = largest depth). A
;; deeper binder is "more inside", hence smaller under ≺. `current-var-depths`
;; carries that map down to `var<`; the stepper sets it (refreshed per step) so
;; traces orient equations exactly as the paper does. When it is unset (the
;; `run`/`vc-eval` exhaustive path, where confluence makes orientation
;; irrelevant) every variable reads as depth 0 and we fall back to the original
;; name heuristic — preserving the established `run` behavior.
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

;; The original name-based heuristic, used only as a same-depth tiebreak (and
;; as the whole order on the depth-less `run` path): α-renamed/fresh names
;; (whose printed form carries a non-alphanumeric marker such as «0») sort as
;; inner, then lexical order. This keeps the relation a deterministic TOTAL
;; order, so VAR-SWAP/SEQ-SWAP cannot ping-pong.
(define (heuristic<? a b)
  (let* ([s1 (symbol->string a)]
         [s2 (symbol->string b)]
         [f1 (regexp-match? #rx"[^a-zA-Z0-9]" s1)]
         [f2 (regexp-match? #rx"[^a-zA-Z0-9]" s2)])
    (cond
      [(and f1 (not f2)) #t]
      [(and (not f1) f2) #f]
      [else (string<? s1 s2)])))

;; x ≺ y, decided lexicographically on (depth descending, then heuristic):
;; deeper binder ⇒ more inside ⇒ smaller. A bound variable (depth ≥ 1) is thus
;; ≺ a free/ambient one (depth 0). Total + antisymmetric ⇒ no swap loops.
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
