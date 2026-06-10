#lang scribble/manual
@(require "../typeset.rkt")

@title[#:tag "core-calculus"]{The core calculus}

All figures in this part are generated from the live Redex model every
time the documentation is built, so they cannot drift from the code.

@section{Grammar}

The grammar of the Verse Calculus (Fig 1 of the paper, plus the Fig 4
contexts), as defined by the model's @racket[VC] language in
@filepath{grammar.rkt}, typeset toward the paper's notation:

@(vc-grammar-pict)

@section{Reduction rules}

The reduction rules (Fig 3), as defined by @racket[vc-->] in
@filepath{rules.rkt}, typeset toward the paper's notation:

@(vc-rules-pict)

The same rules in the model's raw s-expression syntax — the notation that
appears on the small gray line of every figure in the trace chapters:

@(vc-rules-pict/sexp)
