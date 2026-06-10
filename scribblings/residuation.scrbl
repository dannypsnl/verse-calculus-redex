#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.2: residuation}

@verbatim{∃x y. y=7; x=add⟨3, y⟩; x}

The call @tt{add⟨3,y⟩} is @emph{stuck} initially: @racket[APP-ADD] fires only
when both arguments are integer literals, and @racket[y] is still unknown.
Functional-logic programs do not evaluate left-to-right; the call
@emph{residuates} — it suspends until unification supplies @tt{y=7}, after which
the arithmetic proceeds.

@(trace-pict residuation-path)

@section{Step 1 — SUBST}

@racket[APP-ADD] cannot fire while @racket[y] is unbound, so the productive move
is to propagate @tt{y=7} into the rest of the sequence (side conditions hold:
@racket[y] occurs later, @racket[7] is not a variable, @tt{y ∉ fvs(7)}).  The
suspended call becomes @tt{add⟨3,7⟩} — residuation in action.

@(step-pict residuation-path 1)

@section{Step 2 — EQN-ELIM}

@racket[y] now occurs nowhere outside @tt{y=7}, so @racket[EQN-ELIM] removes the
equation and its @tt{∃y} binder.

@(step-pict residuation-path 2)

@section{Step 3 — APP-ADD}

Both arguments are now literals, so the call wakes up: @tt{add⟨3,7⟩} reduces to
@racket[10] (the evaluator's compatible closure reaches it inside the equation's
RHS).  The equation becomes @tt{x=10}.

@(step-pict residuation-path 3)

@section{Step 4 — SUBST}

@tt{x=10} is solved; @racket[SUBST] propagates @racket[10] into the result
position.  The equation and @tt{∃x} binder remain for now.

@(step-pict residuation-path 4)

@section{Step 5 — EQN-ELIM}

@racket[x] is isolated; @racket[EQN-ELIM] removes @tt{∃x} and @tt{x=10}, leaving
@tt{one{10}}.

@(step-pict residuation-path 5)

@section{Step 6 — ONE-VALUE}

@racket[ONE-VALUE] unwraps @tt{one{10}} to @racket[10].

@(step-pict residuation-path 6)
