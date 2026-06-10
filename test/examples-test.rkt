#lang racket/base
(require redex/reduction-semantics
         "../grammar.rkt"
         "../eval.rkt")

;; §1 opening example: ∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y  -->  2
(test-equal
  (run (term (exists x (exists y (exists z
                                         (seq (eqn x (tup y 3)) (seq (eqn x (tup 2 z)) y)))))))
  (term 2))

;; §2.1 first⟨2,5⟩ = 2, where first := λp. ∃a b. p=⟨a,b⟩; a
;;   inlined: ∃p. p=⟨2,5⟩; (∃a b. p=⟨a,b⟩; a)
(test-equal
  (run (term (exists p (seq (eqn p (tup 2 5))
                            (exists a (exists b (seq (eqn p (tup a b)) a)))))))
  (term 2))

;; §2.2 residuation: ∃x y. y=7; x=(add⟨3,y⟩); x  -->  10
(test-equal
  (run (term (exists x (exists y
                               (seq (eqn y 7) (seq (eqn x (app add (tup 3 y))) x))))))
  (term 10))

;; §2.5 if (x=0) then e2 else e3 desugar, closed instance with e2=10, e3=20:
;;   one{ (one{ 1=1 ; 10 }) | 20 }  -->  10
(test-equal
  (run (term (one (choose (one (seq (eqn 1 1) 10)) 20))))
  (term 10))

;; §2.6 tuple indexing as choice: all{ ∃i. ⟨10,27,32⟩(i) }  -->  ⟨10,27,32⟩
(test-equal
  (run (term (all (exists i (app (tup 10 27 32) i)))))
  (term (tup 10 27 32)))

(test-results)
