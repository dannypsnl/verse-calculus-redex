#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §1: two views of one tuple}

The paper's §1 opening example:

@verbatim{∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y}

@racket[x] is described twice — as @tt{⟨y,3⟩} and as @tt{⟨2,z⟩}.  Unification
reconciles the two views, forcing @tt{y=2} and @tt{z=3}; the program returns
@racket[y], so the answer is @racket[2].

@(trace-pict opening-path)

@section{Step 1 — SUBST}

@tt{x=⟨y,3⟩} defines @racket[x], and the @racket[SUBST] side conditions hold
(@racket[x] occurs outside its equation; @tt{x ∉ fvs(⟨y,3⟩)}; the RHS is not a
variable).  It rewrites the @emph{occurrence} of @racket[x] in the second
equation while leaving the defining one in place: the second conjunct becomes
@tt{⟨y,3⟩=⟨2,z⟩}.

@(step-pict opening-path 1)

@section{Step 2 — U-TUP}

Both sides of @tt{⟨y,3⟩=⟨2,z⟩} are equal-arity tuples, so @racket[U-TUP]
decomposes it componentwise into @tt{y=2; 3=z}.

@(step-pict opening-path 2)

@section{Step 3 — HNF-SWAP}

@tt{3=z} has a literal on the left and a variable on the right; @racket[HNF-SWAP]
flips it to @tt{z=3} (the model keeps equations variable-first).

@(step-pict opening-path 3)

@section{Step 4 — EQN-ELIM}

@racket[z] occurs nowhere else, so @racket[EQN-ELIM] drops @tt{z=3} and its
@tt{∃z} binder together.

@(step-pict opening-path 4)

@section{Step 5 — SUBST}

@racket[SUBST] fires for @tt{y=2}, substituting @emph{leftward} as well: the
@racket[y] inside @tt{x=⟨y,3⟩} and the @racket[y] in result position both become
@racket[2].  The equation @tt{y=2} is kept.

@(step-pict opening-path 5)

@section{Step 6 — EQN-ELIM}

@racket[y] is now isolated; @racket[EQN-ELIM] removes @tt{∃y} and @tt{y=2}.

@(step-pict opening-path 6)

@section{Step 7 — EQN-ELIM}

@racket[x] does not appear in the answer; @racket[EQN-ELIM] removes @tt{∃x} and
@tt{x=⟨2,3⟩}.

@(step-pict opening-path 7)

@section{Step 8 — ONE-VALUE}

@racket[ONE-VALUE] unwraps @tt{one{2}} to @racket[2].

@(step-pict opening-path 8)

@section{Why a curated path?}

From @racket[t0], @racket[EXI-SWAP] can permute the adjacent @tt{∃x ∃y ∃z}
binders endlessly, so a greedy stepper never terminates; @racket[SUBST] also
admits two directions at step 1.  Confluence
(@filepath{test/confluence-test.rkt}) guarantees every terminating path agrees
on @racket[2], so checking one curated path — re-verified edge by edge against
the model — suffices.
