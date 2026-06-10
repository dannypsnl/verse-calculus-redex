#lang scribble/manual

@title[#:tag "learn-by-steps" #:style '(toc)]{Learn the calculus by steps}

This part teaches the calculus by example.  Each chapter collects a
machine-checked trace of one paper derivation, walking through it step by
step, with every figure — reduction diagrams and per-step typesetting —
generated from the Redex model when the manual is built.  In every diagram,
each node shows the paper notation above its s-expression form, and gray
@tt{↪} stubs mark the other rules that could legally fire at that state.
Each path starts from @racket[(one _)] wrapping the program, exactly as
@racket[run] does (Fig 1: a program is evaluated under @racket[one]).

@local-table-of-contents[]

@section{How the traces are verified}

Every reduction step shown in the trace chapters lives as data in
@filepath{traces/paths.rkt}.  Requiring that module — which
happens on every build of this manual — re-verifies each step against the
Redex model's @racket[vc-eval] relation (via @racket[must-step], up to
α-equivalence) and checks that each final term is a genuine normal form.
The same paths are covered in CI by

@verbatim{raco test test/}

which additionally cross-checks every curated answer against @racket[run],
the evaluator that explores the @emph{entire} reduction graph.  A failure
means a reduction step no longer matches the model — the error message lists
the actual successors, making it easy to identify which rule changed.

@section{Exploring reduction graphs interactively}

To open the Redex GUI on any example's full reduction graph, start a Racket
REPL and require the relevant program and the stepper:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,opening))
]

Replace @racket[opening] with any of the other names exported by
@filepath{traces/programs.rkt} (@racket[first-apply],
@racket[residuation], @racket[if-true], @racket[if-false],
@racket[tuple-indexing]) to explore the other examples.

@include-section["opening.scrbl"]
@include-section["residuation.scrbl"]
@include-section["first.scrbl"]
@include-section["if-then-else.scrbl"]
@include-section["tuple-indexing.scrbl"]
