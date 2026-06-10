#lang racket/base

;; verse-calculus-redex: a PLT Redex formalization of the core Verse Calculus,
;; from *The Verse Calculus: a Core Calculus for Functional Logic Programming*
;; (Fig 1 grammar, Fig 4 contexts, Fig 3 rewrite rules).
;;
;; This module re-exports the public API. The pieces:
;;   grammar.rkt   - define-language VC (terms + contexts, binding forms)
;;   metafns.rkt   - fvs, variable order, side-condition + builder metafunctions
;;   rules.rkt     - vc--> , every Fig 3 rule tagged with its paper name
;;   eval.rkt      - vc-eval (compatible closure of vc-->) and run
;;   pretty.rkt    - render terms toward the paper's notation
;;   stepper.rkt   - explore the relation interactively (step/steps/print-steps/trace)
;;   typeset.rkt   - paper-style pict typesetting of the grammar and rules

(require "grammar.rkt"
         "metafns.rkt"
         "rules.rkt"
         "eval.rkt"
         "pretty.rkt"
         "stepper.rkt"
         "typeset.rkt")

(provide (all-from-out "grammar.rkt"
                       "metafns.rkt"
                       "rules.rkt"
                       "eval.rkt"
                       "pretty.rkt"
                       "stepper.rkt"
                       "typeset.rkt"))

(module+ test
  (require rackunit)
  ;; A sanity check that the whole pipeline is wired up: the paper's opening
  ;; example ∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y reduces to 2.
  (check-equal?
   (run '(exists x (exists y (exists z
           (seq (eqn x (tup y 3)) (seq (eqn x (tup 2 z)) y))))))
   2)
  (check-equal? (steps '(app add (tup 3 4))) 7))
