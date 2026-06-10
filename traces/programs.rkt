#lang racket/base
;; The paper examples traced in the literate documents of this directory,
;; UNWRAPPED (no `one` around them) — `run` from ../eval.rkt adds the
;; `(one _)` wrapper itself, and each document's t0 is `(one ,program).
;; Handy for GUI exploration too:
;;   (require "redex-model/traces/programs.rkt" "redex-model/stepper.rkt")
;;   (trace `(one ,opening))
(provide opening first-apply residuation if-true if-false tuple-indexing)

;; §1: ∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y  ⇒  2
(define opening
  '(exists x (exists y (exists z
    (seq (eqn x (tup y 3)) (seq (eqn x (tup 2 z)) y))))))

;; §2.1: first⟨2,5⟩ where first = λp. ∃a b. p=⟨a,b⟩; a  ⇒  2
(define first-apply
  '(app (lam p (exists a (exists b (seq (eqn p (tup a b)) a))))
        (tup 2 5)))

;; §2.2 residuation: ∃x y. y=7; x=add⟨3,y⟩; x  ⇒  10
(define residuation
  '(exists x (exists y
    (seq (eqn y 7) (seq (eqn x (app add (tup 3 y))) x)))))

;; §2.5 if (1=1) then 10 else 20, desugared:  one{(one{1=1; 10}) | 20}  ⇒  10
(define if-true
  '(choose (one (seq (eqn 1 1) 10)) 20))

;; §2.5 the failing condition: one{(one{1=2; 10}) | 20}  ⇒  20
(define if-false
  '(choose (one (seq (eqn 1 2) 10)) 20))

;; §2.6 tuple indexing as choice: all{∃i. ⟨10,27,32⟩(i)}  ⇒  ⟨10,27,32⟩
(define tuple-indexing
  '(all (exists i (app (tup 10 27 32) i))))
