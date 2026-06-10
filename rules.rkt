#lang racket/base
(require redex/reduction-semantics "grammar.rkt" "metafns.rkt")
(provide vc-->)

;; The faithful Verse Calculus reduction relation (Fig 3).
(define vc-->
  (reduction-relation VC
                      #:domain e
                      ;; ---------------- Application ----------------
                      (--> (app add (tup k_1 k_2)) ,(+ (term k_1) (term k_2)) "APP-ADD")
                      (--> (app gt (tup k_1 k_2)) k_1
                           (side-condition (> (term k_1) (term k_2))) "APP-GT")
                      (--> (app gt (tup k_1 k_2)) fail
                           (side-condition (<= (term k_1) (term k_2))) "APP-GT-FAIL")
                      (--> (app (lam x e) v)
                           (exists x_new (seq (eqn x_new v) (substitute e x x_new)))
                           (where x_new ,(variable-not-in (term (v e)) (term x)))
                           "APP-BETA")
                      (--> (app (tup v_0 v_1 ...) v)
                           (exists x_new (seq (eqn x_new v) (index-choices x_new (v_0 v_1 ...) 0)))
                           (where x_new ,(variable-not-in (term (v v_0 v_1 ...)) (term x)))
                           "APP-TUP")
                      (--> (app (tup) v) fail "APP-TUP-0")
                      ;; ---------------- Unification ----------------
                      (--> (seq (eqn k_1 k_2) e) e
                           (side-condition (= (term k_1) (term k_2))) "U-LIT")
                      (--> (seq (eqn (tup v_1 ...) (tup v_2 ...)) e)
                           (unify-tup (v_1 ...) (v_2 ...) e)
                           (side-condition (= (length (term (v_1 ...))) (length (term (v_2 ...)))))
                           "U-TUP")
                      (--> (seq (eqn hnf_1 hnf_2) e) fail
                           (side-condition (term (hnf-clash? hnf_1 hnf_2))) "U-FAIL")
                      (--> (seq (eqn x (in-hole V x)) e) fail
                           (side-condition (not (equal? (term V) (term hole)))) "U-OCCURS")
                      (--> (in-hole X (seq (eqn x v) e))
                           (in-hole (substitute X x v) (seq (eqn x v) (substitute e x v)))
                           (side-condition (memq (term x) (term (fvs (in-hole X e))))) ; x ∈ fvs(X,e)
                           (side-condition (not (memq (term x) (term (fvs v))))) ; x ∉ fvs(v)
                           (side-condition (term (subst-ok? x v))) ; v=y ⟹ x<y
                           "SUBST")
                      ;; ---------------- Swapping ----------------
                      (--> (seq (eqn hnf x) e) (seq (eqn x hnf) e) "HNF-SWAP")
                      (--> (seq (eqn x_1 x_2) e) (seq (eqn x_2 x_1) e)
                           (side-condition (term (var< x_2 x_1))) "VAR-SWAP") ; fires on y=x when x<y
                      (--> (seq eq (seq (eqn x v) e)) (seq (eqn x v) (seq eq e))
                           (side-condition (term (seq-swap-ok? eq x))) "SEQ-SWAP")
                      ;; ---------------- Elimination ----------------
                      (--> (seq v e) e "VAL-ELIM")
                      (--> (exists x e) e
                           (side-condition (not (memq (term x) (term (fvs e))))) "EXI-ELIM")
                      (--> (exists x (in-hole X (seq (eqn x v) e))) (in-hole X e)
                           (side-condition (not (memq (term x) (term (fvs (in-hole X (seq v e)))))))
                           "EQN-ELIM")
                      (--> (in-hole X fail) fail
                           (side-condition (not (equal? (term X) (term hole)))) "FAIL-ELIM")
                      ;; ---------------- Normalization ----------------
                      (--> (seq (seq eq e_1) e_2) (seq eq (seq e_1 e_2)) "SEQ-ASSOC")
                      (--> (seq (eqn v (seq eq e_1)) e_2) (seq eq (seq (eqn v e_1) e_2)) "EQN-FLOAT")
                      (--> (exists x (exists y e)) (exists y (exists x e)) "EXI-SWAP")
                      (--> (in-hole X (exists x e))
                           (exists x_new (in-hole X (substitute e x x_new)))
                           (where x_new ,(variable-not-in (term (in-hole X e)) (term x)))
                           (side-condition (not (equal? (term X) (term hole))))
                           "EXI-FLOAT")
                      ;; ---------------- Choice ----------------
                      (--> (one fail) fail "ONE-FAIL")
                      (--> (one v) v "ONE-VALUE")
                      (--> (one (choose v e)) v "ONE-CHOICE")
                      (--> (all fail) (tup) "ALL-FAIL")
                      (--> (all v) (tup v) "ALL-VALUE")
                      ;; all-choice: all{v1 | ··· | vn} → ⟨v1,···,vn⟩ (n ≥ 2; the
                      ;; (choose ...) shape keeps it disjoint from ALL-VALUE)
                      (--> (all (choose e_1 e_2)) (tup v ...)
                           (where (v ...) (flat-choice (choose e_1 e_2))) "ALL-CHOICE")
                      (--> (choose fail e) e "CHOOSE-R")
                      (--> (choose e fail) e "CHOOSE-L")
                      (--> (choose (choose e_1 e_2) e_3) (choose e_1 (choose e_2 e_3)) "CHOOSE-ASSOC")
                      (--> (in-hole SX (in-hole CX (choose e_1 e_2)))
                           (in-hole SX (choose (in-hole CX e_1) (in-hole CX e_2)))
                           (side-condition (not (equal? (term CX) (term hole)))) "CHOOSE")))
