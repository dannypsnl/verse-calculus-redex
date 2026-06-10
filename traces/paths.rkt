#lang racket/base
;; The curated derivation paths of the literate trace documents — the single
;; source of truth consumed by both the documents (figure generation) and the
;; tests. Requiring this module re-verifies every step against vc-eval via
;; `must-step` (up to α-equivalence) and checks each final term with
;; `must-be-stuck`, so a documentation build fails loudly — with must-step's
;; list of actual successors — if a rule change invalidates a path.
(require "trace-lib.rkt" "programs.rkt")
(provide (struct-out trace-path)
         path-term path-rule path-length
         opening-path first-path residuation-path
         if-true-path if-false-path tuple-indexing-path)

;; name : symbol; t0 : initial term; steps : (listof (cons rule-name term))
(struct trace-path (name t0 steps) #:transparent)

;; path-term: the term after i steps (0 = the initial (one _)-wrapped term)
(define (path-term p i)
  (if (zero? i)
      (trace-path-t0 p)
      (cdr (list-ref (trace-path-steps p) (sub1 i)))))

;; path-rule: the rule of step i (1-based, matching the documents' sections)
(define (path-rule p i)
  (car (list-ref (trace-path-steps p) (sub1 i))))

(define (path-length p)
  (length (trace-path-steps p)))

;; fold must-step over the steps, then insist the result is a normal form
(define (verified-path name program steps)
  (define t0 `(one ,program))
  (define tn
    (for/fold ([t t0]) ([s (in-list steps)])
      (must-step t (car s) (cdr s))))
  (must-be-stuck tn)
  (trace-path name t0 steps))

;; ---- §1 opening: ∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y  ⇒  2 ----
(define opening-path
  (verified-path
   'opening opening
   '(("SUBST" . (one (exists x (exists y (exists z
                   (seq (eqn x (tup y 3))
                        (seq (eqn (tup y 3) (tup 2 z)) y)))))))
     ("U-TUP" . (one (exists x (exists y (exists z
                   (seq (eqn x (tup y 3))
                        (seq (eqn y 2) (seq (eqn 3 z) y))))))))
     ("HNF-SWAP" . (one (exists x (exists y (exists z
                      (seq (eqn x (tup y 3))
                           (seq (eqn y 2) (seq (eqn z 3) y))))))))
     ("EQN-ELIM" . (one (exists x (exists y
                      (seq (eqn x (tup y 3)) (seq (eqn y 2) y))))))
     ("SUBST" . (one (exists x (exists y
                   (seq (eqn x (tup 2 3)) (seq (eqn y 2) 2))))))
     ("EQN-ELIM" . (one (exists x (seq (eqn x (tup 2 3)) 2))))
     ("EQN-ELIM" . (one 2))
     ("ONE-VALUE" . 2))))

;; ---- §2.1 first⟨2,5⟩  ⇒  2 ----
(define first-path
  (verified-path
   'first-apply first-apply
   '(("APP-BETA" . (one (exists p (seq (eqn p (tup 2 5))
                      (exists a (exists b (seq (eqn p (tup a b)) a)))))))
     ("SUBST" . (one (exists p (seq (eqn p (tup 2 5))
                   (exists a (exists b (seq (eqn (tup 2 5) (tup a b)) a)))))))
     ("EQN-ELIM" . (one (exists a (exists b
                      (seq (eqn (tup 2 5) (tup a b)) a)))))
     ("U-TUP" . (one (exists a (exists b
                   (seq (eqn 2 a) (seq (eqn 5 b) a))))))
     ("HNF-SWAP" . (one (exists a (exists b
                      (seq (eqn 2 a) (seq (eqn b 5) a))))))
     ("EQN-ELIM" . (one (exists a (seq (eqn 2 a) a))))
     ("HNF-SWAP" . (one (exists a (seq (eqn a 2) a))))
     ("SUBST" . (one (exists a (seq (eqn a 2) 2))))
     ("EQN-ELIM" . (one 2))
     ("ONE-VALUE" . 2))))

;; ---- §2.2 residuation: ∃x y. y=7; x=add⟨3,y⟩; x  ⇒  10 ----
(define residuation-path
  (verified-path
   'residuation residuation
   '(("SUBST" . (one (exists x (exists y
                   (seq (eqn y 7) (seq (eqn x (app add (tup 3 7))) x))))))
     ("EQN-ELIM" . (one (exists x (seq (eqn x (app add (tup 3 7))) x))))
     ("APP-ADD" . (one (exists x (seq (eqn x 10) x))))
     ("SUBST" . (one (exists x (seq (eqn x 10) 10))))
     ("EQN-ELIM" . (one 10))
     ("ONE-VALUE" . 10))))

;; ---- §2.5 if/then/else, true branch: one{one{1=1; 10} | 20}  ⇒  10 ----
(define if-true-path
  (verified-path
   'if-true if-true
   '(("U-LIT" . (one (choose (one 10) 20)))
     ("ONE-VALUE" . (one (choose 10 20)))
     ("ONE-CHOICE" . 10))))

;; ---- §2.5 if/then/else, false branch: one{one{1=2; 10} | 20}  ⇒  20 ----
(define if-false-path
  (verified-path
   'if-false if-false
   '(("U-FAIL" . (one (choose (one fail) 20)))
     ("ONE-FAIL" . (one (choose fail 20)))
     ("CHOOSE-R" . (one 20))
     ("ONE-VALUE" . 20))))

;; ---- §2.6 tuple indexing: all{∃i. ⟨10,27,32⟩(i)}  ⇒  ⟨10,27,32⟩ ----
;; The three-way choice APP-TUP builds recurs verbatim in steps 1-4.
(define tup-body
  '(choose (seq (eqn x 0) 10)
           (choose (seq (eqn x 1) 27) (seq (eqn x 2) 32))))

(define tuple-indexing-path
  (verified-path
   'tuple-indexing tuple-indexing
   `(("APP-TUP" . (one (all (exists i (exists x (seq (eqn x i) ,tup-body))))))
     ("EXI-SWAP" . (one (all (exists x (exists i (seq (eqn x i) ,tup-body))))))
     ("VAR-SWAP" . (one (all (exists x (exists i (seq (eqn i x) ,tup-body))))))
     ("EQN-ELIM" . (one (all (exists x ,tup-body))))
     ("CHOOSE" . (one (all (choose (exists x (seq (eqn x 0) 10))
                                   (exists x (choose (seq (eqn x 1) 27)
                                                     (seq (eqn x 2) 32)))))))
     ("CHOOSE" . (one (all (choose (exists x (seq (eqn x 0) 10))
                                   (choose (exists x (seq (eqn x 1) 27))
                                           (exists x (seq (eqn x 2) 32)))))))
     ("EQN-ELIM" . (one (all (choose 10
                                     (choose (exists x (seq (eqn x 1) 27))
                                             (exists x (seq (eqn x 2) 32)))))))
     ("EQN-ELIM" . (one (all (choose 10
                                     (choose 27 (exists x (seq (eqn x 2) 32)))))))
     ("EQN-ELIM" . (one (all (choose 10 (choose 27 32)))))
     ("ALL-CHOICE" . (one (tup 10 27 32)))
     ("ONE-VALUE" . (tup 10 27 32)))))
