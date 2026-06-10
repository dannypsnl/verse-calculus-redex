#lang racket/base
(module+ test
  (require redex/reduction-semantics
           "../grammar.rkt"
           "../metafns.rkt"
           rackunit)

  ;; var<: a total order on variables (approximates the paper's ≺; documented)
  (check-true (term (var< a b)))
  (check-false (term (var< b a)))
  (check-false (term (var< a a)))

  ;; regression: a freshly-renamed (marker-bearing) binder is treated as INNER,
  ;; so it sorts before a plain source variable (this is the ≺ approximation that
  ;; keeps VAR-SWAP from flipping an inner binder rightward past a free var, which
  ;; would block EQN-ELIM — see metafns.rkt and the confluence fix).
  (check-true (term (var< |d«0»| g))) ; fresh/inner < plain/outer
  (check-false (term (var< g |d«0»|))) ; plain/outer is not < fresh/inner

  ;; subst-ok?: (subst-ok? x v) is true iff v is NOT a variable, or v is a
  ;; variable y with x < y.
  (check-true (term (subst-ok? x 3))) ; v is not a variable        -> ok
  (check-true (term (subst-ok? a b))) ; v=b variable, x=a, a<b      -> ok
  (check-false (term (subst-ok? b a))) ; v=a variable, x=b, not b<a  -> not ok

  ;; hnf-clash?: true when two head-values definitely cannot unify (⟶ U-FAIL)
  (check-true (term (hnf-clash? 3 (tup 1 2)))) ; int vs tuple
  (check-true (term (hnf-clash? (tup 1) (tup 1 2)))) ; different arity
  (check-true (term (hnf-clash? add gt))) ; different primops
  (check-false (term (hnf-clash? 3 3))) ; equal ints: no clash (U-LIT)
  (check-false (term (hnf-clash? (tup 1 2) (tup 3 4)))) ; same arity: no clash (U-TUP)
  ;; a lambda vs ANY value — including another lambda or itself — does NOT clash:
  ;; the equation is STUCK, not failed (paper Fig 3 / §3.2: equality of functions
  ;; is undecidable, so U-FAIL excludes lambdas).
  (check-false (term (hnf-clash? (lam x x) (lam y y)))) ; λ vs λ: stuck
  (check-false (term (hnf-clash? (lam x x) 3))) ; λ vs int: stuck
  (check-false (term (hnf-clash? 3 (lam x x)))) ; int vs λ: stuck (symmetric)
  (check-false (term (hnf-clash? (lam x x) add))) ; λ vs op: stuck

  (displayln "side-test ok"))
