#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.5: if/then/else, both branches}

The Verse Calculus has no boolean type or conditional.  Instead
@tt{if e then e2 else e3} desugars to @tt{one{(one{e; e2}) | e3}}.  The inner
@tt{one{e; e2}} runs the condition and, on success, continues to the
then-payload; on failure it yields @tt{fail}.  The outer @tt{one} then commits
to the first surviving alternative of @tt{fail | e3} — selecting the
then-result on success, or routing to @tt{e3} on failure.  So @tt{fail} and
@tt{choose} give @tt{else} for free.

This document traces two closed instances:
@itemlist[
  @item{The @bold{true branch}: condition @tt{1=1}, then @tt{10}, else @tt{20}.
        Result: @racket[10].}
  @item{The @bold{false branch}: condition @tt{1=2}, then @tt{10}, else @tt{20}.
        Result: @racket[20].}
]

@section{The true branch}

@(trace-pict if-true-path)

@subsection{Step 1 — U-LIT}

The condition @tt{1=1} equates two identical literals, so @racket[U-LIT]
consumes it and the sequence continues to its payload @tt{10}.  (With different
literals this same position would fail — see the false branch.)

@(step-pict if-true-path 1)

@subsection{Step 2 — ONE-VALUE}

@racket[ONE-VALUE] unwraps the inner @tt{one{10}} to @tt{10}, exposing it as the
left alternative of the outer choice.

@(step-pict if-true-path 2)

@subsection{Step 3 — ONE-CHOICE}

The outer @tt{one} sees @tt{10 | 20} with a value on the left, so
@racket[ONE-CHOICE] commits to @tt{10} and @emph{discards @tt{20} unevaluated} —
this commitment is what makes @tt{if/then/else} deterministic.

@(step-pict if-true-path 3)

@section{The false branch}

@(trace-pict if-false-path)

@subsection{Step 1 — U-FAIL}

The condition @tt{1=2} equates two @emph{different} literals; @racket[hnf-clash?]
detects the clash and @racket[U-FAIL] rewrites the whole sequence @tt{1=2; 10}
to @tt{fail}, wiping out the then-payload.

@(step-pict if-false-path 1)

@subsection{Step 2 — ONE-FAIL}

@racket[ONE-FAIL] propagates the failure out of the inner wrapper:
@tt{one{fail}} reduces to @tt{fail}.

@(step-pict if-false-path 2)

@subsection{Step 3 — CHOOSE-R}

@racket[CHOOSE-R] reduces @tt{fail | e3} to @tt{e3}: the failed left alternative
is discarded, selecting the else-branch.

@(step-pict if-false-path 3)

@subsection{Step 4 — ONE-VALUE}

@racket[ONE-VALUE] unwraps @tt{one{20}} to @racket[20].

@(step-pict if-false-path 4)
