#lang racket/base
;; The paper's variable order x ≺ y means "x is bound inside y", so VAR-SWAP
;; orients equations with the INNERMOST-bound variable on the left (paper §3.3).
;; The stepper recovers that order from each term's binder nesting via
;; `binder-depths` / `current-var-depths`, so traces match the paper even for
;; plain source variables (whose names carry no nesting information).
(require "../stepper.rkt" "../metafns.rkt" redex/reduction-semantics rackunit)

(define (rules-of t) (map car (step t)))

;; ∃a. ∃b. (b = a; b = 3; a)  — a is OUTER, b is INNER, so b ≺ a.
;; b is already on the left of (b = a): the equation is canonical, so VAR-SWAP
;; must NOT fire. (With a name-only heuristic, "a" < "b" alphabetically would
;; wrongly swap it.)
(define inner-left
  (term (exists a (exists b (seq (eqn b a) (seq (eqn b 3) a))))))
(check-false (member "VAR-SWAP" (rules-of inner-left))
             "b≺a and b is on the left: VAR-SWAP should not fire")

;; ∃a. ∃b. (a = b; b = 3; a)  — same nesting, but the OUTER variable a is on the
;; left, so VAR-SWAP must fire and flip it to (b = a).
(define outer-left
  (term (exists a (exists b (seq (eqn a b) (seq (eqn b 3) a))))))
(check-true (and (member "VAR-SWAP" (rules-of outer-left)) #t)
            "a≺b is false (a outer): VAR-SWAP should flip a=b to b=a")
(check-not-false
 (member (term (exists a (exists b (seq (eqn b a) (seq (eqn b 3) a)))))
         (map cdr (step outer-left)))
 "the VAR-SWAP successor puts the inner b on the left")

;; Both orientations still evaluate to the same value (confluence): 3.
(check-equal? (run inner-left) 3)
(check-equal? (run outer-left) 3)

;; binder-depths: deeper binder ⇒ larger depth ⇒ smaller under ≺.
(define dm (binder-depths (term (exists a (exists b (seq (eqn b a) b))))))
(check-equal? (hash-ref dm (term a)) 1) ; outer
(check-equal? (hash-ref dm (term b)) 2) ; inner

;; Off the stepper path (current-var-depths unset) ≺ falls back to the name
;; heuristic, preserving the established run/vc-eval behavior.
(check-false (current-var-depths))

(displayln "var-order-test ok")
