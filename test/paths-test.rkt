#lang racket/base
;; The real verification happens when paths.rkt is instantiated: must-step
;; checks every edge against vc-eval (up to α-equivalence) and must-be-stuck
;; checks each final term. This file makes CI run that, pins the shape of
;; each path, and cross-checks every curated answer against `run`, which
;; explores the ENTIRE reduction graph rather than one hand-picked path.
(require rackunit
         "../traces/paths.rkt"
         "../traces/programs.rkt"
         "../eval.rkt")

;; shapes
(check-equal? (path-length opening-path) 8)
(check-equal? (path-length first-path) 10)
(check-equal? (path-length residuation-path) 6)
(check-equal? (path-length if-true-path) 3)
(check-equal? (path-length if-false-path) 4)
(check-equal? (path-length tuple-indexing-path) 11)

;; first rules, matching the documents' Step 1 sections
(check-equal? (path-rule opening-path 1) "SUBST")
(check-equal? (path-rule first-path 1) "APP-BETA")
(check-equal? (path-rule residuation-path 1) "SUBST")
(check-equal? (path-rule if-true-path 1) "U-LIT")
(check-equal? (path-rule if-false-path 1) "U-FAIL")
(check-equal? (path-rule tuple-indexing-path 1) "APP-TUP")

;; path-term 0 is the (one _)-wrapped program
(check-equal? (path-term opening-path 0) `(one ,opening))

;; every curated answer agrees with the full-graph evaluator
(check-equal? (path-term opening-path 8) (run opening))
(check-equal? (path-term first-path 10) (run first-apply))
(check-equal? (path-term residuation-path 6) (run residuation))
(check-equal? (path-term if-true-path 3) (run if-true))
(check-equal? (path-term if-false-path 4) (run if-false))
(check-equal? (path-term tuple-indexing-path 11) (run tuple-indexing))
