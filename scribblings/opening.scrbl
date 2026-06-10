#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §1: two views of one tuple}

The paper's §1 opening example is the program

@verbatim{∃x y z. x=⟨y,3⟩; x=⟨2,z⟩; y}

The variable @racket[x] is described twice: once as @tt{⟨y,3⟩} and once as
@tt{⟨2,z⟩}.  Unification must reconcile these two views, which forces
@tt{y=2} and @tt{z=3}.  The expression ends by returning @racket[y], so
the whole program yields @racket[2].

Every figure below is generated from the Redex model when this manual is
built: the module that defines the curated path
(@filepath{traces/paths.rkt}) re-verifies each reduction step
against the model's @racket[vc-eval] relation (via @racket[must-step], up to
α-equivalence) whenever it is required, so the figures cannot silently drift
from the model.

The path starts from @racket[t0], which wraps the unwrapped program exported
from @filepath{programs.rkt} in @racket[(one _)], exactly as the model's
@racket[run] does: Fig 1 of the paper specifies that a program is evaluated
under @racket[one], which yields exactly one result or fails.

The full eight-step path we will follow — each node shows the paper notation
above its s-expression form, and the gray @tt{↪} annotations list the
@emph{other} rules that could legally fire at that state, computed live from
the model:

@(trace-pict opening-path)

@section{Step 1 — SUBST}

The equation @tt{x=⟨y,3⟩} defines @racket[x].  The side conditions for @racket[SUBST]
are all satisfied: @racket[x] occurs free somewhere outside its defining equation —
in the surrounding execution context or later in the sequence
(@tt{x ∈ fvs(X,e)}); @racket[x] does not appear in its own right-hand side
(@tt{x ∉ fvs(⟨y,3⟩)}, so there is no occurs-check violation); and because the
right-hand side is not a variable, the variable-ordering side condition is
trivially satisfied.  @racket[SUBST] rewrites the @emph{occurrence} of @racket[x] in
the second equation while leaving the defining equation in place: the second
conjunct becomes @tt{⟨y,3⟩=⟨2,z⟩}, placing the two views of @racket[x] face
to face.

@(step-pict opening-path 1)

@section{Step 2 — U-TUP}

Both sides of @tt{⟨y,3⟩=⟨2,z⟩} are tuples of equal arity, so the
@racket[U-TUP] rule applies.  Via the @racket[unify-tup] metafunction it
decomposes the single tuple equation into a sequence of componentwise equations:
@tt{y=2; 3=z}.  This is a purely structural step — no concrete values have
been substituted into variables yet.

@(step-pict opening-path 2)

@section{Step 3 — HNF-SWAP}

The equation @tt{3=z} has a head-normal form (a literal integer) on the left
and a variable on the right.  The model keeps equations in variable-first
orientation, so @racket[HNF-SWAP] flips it to @tt{z=3}.  The adjacent
equation @tt{y=2} is already oriented correctly and is unaffected.

@(step-pict opening-path 3)

@section{Step 4 — EQN-ELIM}

The equation @tt{z=3} now has @racket[z] in solved position.  Because
@racket[z] does not appear anywhere else in the term (it is not free in the
rest of the sequence), neither its defining equation nor the enclosing @tt{∃z} binder is needed
any longer — @racket[EQN-ELIM] removes them together.

@(step-pict opening-path 4)

@section{Step 5 — SUBST}

@racket[SUBST] fires again, this time for @tt{y=2}.  Note that this substitutes
@emph{leftward} into the execution context as well: the occurrence of @racket[y]
inside @tt{x=⟨y,3⟩} becomes @racket[2], as does the occurrence of @racket[y]
in the result position.  After this step both become @racket[2], and the
equation @tt{y=2} is retained (the binder is not yet removed).

@(step-pict opening-path 5)

@section{Step 6 — EQN-ELIM}

@racket[y] no longer appears anywhere outside its defining equation @tt{y=2};
the variable is isolated.  @racket[EQN-ELIM] removes both the @tt{∃y} binder
and the equation.

@(step-pict opening-path 6)

@section{Step 7 — EQN-ELIM}

By the same reasoning, @racket[x] does not appear in the answer @racket[2];
@racket[EQN-ELIM] removes @tt{∃x} and @tt{x=⟨2,3⟩}, leaving a closed term.

@(step-pict opening-path 7)

@section{Step 8 — ONE-VALUE}

@tt{one{2}} wraps a single concrete value, so @racket[ONE-VALUE] simply
unwraps it: @racket[(one 2)] reduces to @racket[2].

@(step-pict opening-path 8)

@section{Final check}

Whenever this manual is built, the path's final term is confirmed to be a
genuine normal form (no further reduction rule applies, via
@racket[must-be-stuck]); and @filepath{test/paths-test.rkt}
cross-checks the curated answer against @racket[run], which explores the
@emph{entire} reduction graph rather than following a single hand-picked
path.  Both must agree on @racket[2].

Why did we hand-pick a path at all?  Starting from @racket[t0], the
@racket[EXI-SWAP] rule can permute the adjacent @tt{∃x ∃y ∃z} binders in any
order — a greedy stepper chases this permutation cycle indefinitely, producing
α-renamed names like @tt{y«8544»} and never terminating.  Even @racket[SUBST]
admits two directions at the first step.  Confluence (probed in
@filepath{test/confluence-test.rkt}) guarantees that every
terminating path agrees on @racket[2], which is why checking the curated path
suffices.

@section{Exploring interactively}

To walk the full reduction graph in the Redex GUI, start a Racket REPL at the
repo root and evaluate:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,opening))
]
