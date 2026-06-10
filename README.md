verse-calculus-redex
====================

A [PLT Redex](https://redex.racket-lang.org/) formalization of the core Verse
Calculus, from *The Verse Calculus: a Core Calculus for Functional Logic
Programming* (Fig 1 grammar, Fig 4 contexts, Fig 3 rewrite rules).

Stepping the model
------------------

Terms are plain s-expressions (no need for Redex's `term`).

```racket
(require verse-calculus-redex/stepper)

;; `step` / `steps` / `print-steps` greedily follow the first successor, so use
;; them on short reductions:
(step '(app add (tup 3 4)))        ; => (("APP-ADD" . 7))
(steps '(app add (tup 3 4)))       ; => 7
(print-steps '(app add (tup 3 4)))
;;     add⟨3, 4⟩
;; ⟶{APP-ADD} 7

;; `run` computes the full Redex normal form (explores all reductions):
(run '(exists x (exists y (exists z
  (seq (eqn x (tup y 3)) (seq (eqn x (tup 2 z)) y))))))   ; => 2

(trace '(app add (tup 3 4)))       ; opens the Redex GUI
```

Literate traces
---------------

The package manual ([`scribblings/`](scribblings/)) walks the paper's examples
derivation step by derivation step — literate `scribble` documents in which
every step is machine-checked against this model (`must-step` from
[`traces/trace-lib.rkt`](traces/trace-lib.rkt) verifies each (rule, term) pair
is a real `vc-eval` successor, up to α-equivalence; the example terms live in
[`traces/programs.rkt`](traces/programs.rkt)).
