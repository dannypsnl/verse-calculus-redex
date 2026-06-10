#lang scribble/manual

@title[#:style '(toc)]{The Verse Calculus, in Redex}
@author{dannypsnl}

@defmodule[verse-calculus-redex]

@racketmodname[verse-calculus-redex] is a @hyperlink["https://redex.racket-lang.org/"]{PLT
Redex} formalization of the core Verse Calculus, from the paper @emph{The Verse
Calculus: a Core Calculus for Functional Logic Programming}.  This manual is in
two parts.  @secref["core-calculus"] presents the calculus itself — its grammar
and reduction rules, typeset from the live Redex model.  @secref["learn-by-steps"]
teaches the calculus by example: each chapter walks through one paper derivation
step by step, with every figure generated from the model when the manual is
built, so the figures cannot drift from the code.

@table-of-contents[]

@include-section["calculus.scrbl"]
@include-section["traces.scrbl"]
