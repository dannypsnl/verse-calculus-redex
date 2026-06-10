#lang info
(define collection "verse-calculus-redex")
(define deps '("base" "redex-lib" "redex-pict-lib" "pict-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/verse-calculus-redex.scrbl" (multi-page))))
(define pkg-desc "A PLT Redex formalization of the core Verse Calculus")
(define version "0.0")
(define pkg-authors '(dannypsnl))
(define license '(Apache-2.0 OR MIT))
