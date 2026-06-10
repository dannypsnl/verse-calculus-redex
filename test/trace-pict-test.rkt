#lang racket/base
;; Smoke tests for the self-drawn reduction diagrams and step figures.
(module+ test
  (require rackunit pict racket/list
           "../trace-pict.rkt"
           "../traces/paths.rkt")

  ;; every diagram and every step figure builds, for every path
  (for ([p (in-list (list opening-path first-path residuation-path
                          if-true-path if-false-path tuple-indexing-path))])
    (define d (trace-pict p))
    (check-true (> (pict-width d) 0) (format "~a diagram" (trace-path-name p)))
    (check-true (> (pict-height d) 0))
    (for ([i (in-range 1 (add1 (path-length p)))])
      (check-true (> (pict-width (step-pict p i)) 0)
                  (format "~a step ~a" (trace-path-name p) i))))

  ;; a longer path yields a taller diagram
  (check-true (> (pict-height (trace-pict tuple-indexing-path))
                 (pict-height (trace-pict if-true-path))))

  ;; stub labels: deduplicated (the ×n form folds repeats away) ...
  (define labels (untaken-labels opening-path 0))
  (check-equal? labels (remove-duplicates labels))
  ;; ... and non-empty at opening's first state, where the prose documents
  ;; genuine alternatives (EXI-SWAP permutations, a second SUBST direction)
  (check-true (pair? labels))

  ;; pin the ×n count: opening's first state offers two EXI-SWAP permutations
  ;; and a second SUBST direction besides the taken edge
  (check-equal? labels '("EXI-SWAP ×2" "SUBST"))
  ;; pin exactly-once removal: first-path node 4 has TWO HNF-SWAP successors
  ;; (only one of them the taken edge), so the other must survive as a stub
  (check-equal? (untaken-labels first-path 4) '("EXI-SWAP" "HNF-SWAP")))
