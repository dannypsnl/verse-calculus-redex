#lang racket/base
;; Smoke tests: the grammar and rules figures build headlessly.
(module+ test
  (require rackunit pict redex/pict "../typeset.rkt" "../grammar.rkt" "../rules.rkt")

  (check-true (> (pict-width (vc-grammar-pict)) 0))
  (check-true (> (pict-height (vc-grammar-pict)) 0))
  (check-true (> (pict-height (vc-rules-pict)) 0))
  (check-true (> (pict-height (vc-rules-pict/sexp)) 0))

  ;; the rewriters must actually fire: "∃x. x = x; x" has far fewer glyphs
  ;; than "(exists x (seq (eqn x x) x))", so the rewritten rendering is
  ;; strictly narrower under any font (comparing whole-figure dimensions
  ;; is font-dependent and flaked on CI)
  (check-true (< (pict-width (with-vc-rewriters (render-term VC (exists x (seq (eqn x x) x)))))
                 (pict-width (render-term VC (exists x (seq (eqn x x) x))))))

  ;; the unquote rewriter must fire: with it, Racket escapes such as
  ;; "(variable-not-in (v e) x)" render as "fresh", so even the raw-sexp
  ;; figure (no compound rewriters) is strictly narrower than a render
  ;; with no rewriters at all, where escapes appear verbatim as pink code
  (check-true (< (pict-width (vc-rules-pict/sexp))
                 (pict-width (render-reduction-relation vc-->)))))
