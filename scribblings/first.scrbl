#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.1: first⟨2,5⟩}

The paper's §2.1 defines the function @tt{first := λp. ∃a b. p=⟨a,b⟩; a}
and applies it to the tuple @tt{⟨2,5⟩}.  The function returns the first
component of a pair.

The headline of this trace is @racket[APP-BETA]: function application in the
Verse Calculus does @emph{not} substitute the argument into the body (there is
no call-by-value substitution).  Instead, β-reduction introduces a fresh
existential @tt{∃p} and an equation @tt{p=⟨2,5⟩} in front of the
otherwise-untouched body.  Application is call-by-unification.  The rest of
the derivation is unification doing what substitution would have done, one
explicit step at a time — the parameter @tt{p} is resolved by the equation, the
tuple equation decomposes, and the components are matched and eliminated
piecewise.  The result is @racket[2], agreeing with §2.1 of the paper.

Every figure below is generated from the Redex model when this manual is
built: the module that defines the curated path
(@filepath{traces/paths.rkt}) re-verifies each reduction step
against the model's @racket[vc-eval] relation (via @racket[must-step], up to
α-equivalence) whenever it is required, so the figures cannot silently drift
from the model.

The path starts from @racket[t0], which wraps the unwrapped program
exported from @filepath{programs.rkt} in @racket[(one _)], exactly as the
model's @racket[run] does: Fig 1 of the paper specifies that a program is
evaluated under @racket[one], which yields exactly one result or fails.

The full ten-step path we will follow — each node shows the paper notation
above its s-expression form, and the gray @tt{↪} annotations list the
@emph{other} rules that could legally fire at that state, computed live from
the model:

@(trace-pict first-path)

@section{Step 1 — APP-BETA}

β-reduction in the Verse Calculus does not perform substitution.  Instead,
@racket[APP-BETA] introduces a fresh existential for the parameter and an
equation binding that parameter to the argument, placing both in front of the
original body.  Here the body @tt{∃a. ∃b. p=⟨a,b⟩; a} is left completely
untouched; the argument @tt{⟨2,5⟩} is not copied into it.  The result is
@tt{∃p. p=⟨2,5⟩; ∃a. ∃b. p=⟨a,b⟩; a}: the fresh @tt{∃p} binder and the
equation @tt{p=⟨2,5⟩} precede the body in sequence.

The model picks a fresh parameter name via @racket[variable-not-in]; the
curated term keeps the name @racket[p], which is α-equivalent to whatever
fresh name the model chose, and @racket[must-step] compares up to
α-equivalence.

@(step-pict first-path 1)

@section{Step 2 — SUBST}

The equation @tt{p=⟨2,5⟩} defines @racket[p].  The side conditions for
@racket[SUBST] are satisfied: @racket[p] occurs free somewhere in the
continuation (inside the inner @tt{∃a ∃b} binders, in the equation
@tt{p=⟨a,b⟩}); the right-hand side @tt{⟨2,5⟩} does not mention @racket[p]
(no occurs-check violation); and because the right-hand side is not a
variable, the variable-ordering side condition is trivially satisfied.
@racket[SUBST] rewrites the occurrence of @racket[p] inside @tt{p=⟨a,b⟩},
replacing it with @tt{⟨2,5⟩} to give @tt{⟨2,5⟩=⟨a,b⟩}.  The defining
equation @tt{p=⟨2,5⟩} is retained; the @tt{∃p} binder persists for now.

@(step-pict first-path 2)

@section{Step 3 — EQN-ELIM}

After the substitution, @racket[p] is fully consumed: it occurs nowhere outside
its defining equation @tt{p=⟨2,5⟩}.  @racket[EQN-ELIM] removes both the
equation and the enclosing @tt{∃p} binder together, leaving the inner
existentials exposed.

@(step-pict first-path 3)

@section{Step 4 — U-TUP}

Both sides of @tt{⟨2,5⟩=⟨a,b⟩} are 2-tuples, so @racket[U-TUP] applies.
Via the @racket[unify-tup] metafunction the single tuple equation decomposes
componentwise into @tt{2=a; 5=b}.  This is a purely structural step — no
concrete values have flowed into variables yet.

@(step-pict first-path 4)

@section{Step 5 — HNF-SWAP}

The equation @tt{5=b} has a head-normal form (integer literal) on the left
and a variable on the right.  @racket[HNF-SWAP] orients it to @tt{b=5}.
Note that @tt{2=a} is equally mis-oriented and either swap would be legal at
this point; the curated path picks @tt{5=b} first purely for narrative flow.
Confluence guarantees the order does not affect the final result.

@(step-pict first-path 5)

@section{Step 6 — EQN-ELIM}

The equation @tt{b=5} now has @racket[b] in solved position.  Crucially,
@racket[b] is used nowhere else in the term: @racket[b] does not appear in
the result position (which holds @racket[a]) nor anywhere else in the
continuation.  @racket[EQN-ELIM] removes both the @tt{∃b} binder and the
equation @tt{b=5} — @emph{without the value 5 ever flowing anywhere}.
Contrast this with @racket[a]: @racket[a] is the result, so its equation
cannot be eliminated until the value has been substituted into the result
position.

@(step-pict first-path 6)

@section{Step 7 — HNF-SWAP}

Now @tt{2=a} is the remaining mis-oriented equation.  @racket[HNF-SWAP]
flips it to @tt{a=2}, putting @racket[a] in solved position.

@(step-pict first-path 7)

@section{Step 8 — SUBST}

With @tt{a=2} now fully solved, @racket[SUBST] propagates the value
@racket[2] into the result position: the trailing @racket[a] in the sequence
becomes @racket[2].  The defining equation @tt{a=2} and the @tt{∃a} binder
remain for now; they will be swept away in the next step.

@(step-pict first-path 8)

@section{Step 9 — EQN-ELIM}

@racket[a] no longer appears anywhere outside its defining equation @tt{a=2}:
the result position now holds the literal @racket[2].  @racket[EQN-ELIM]
removes both the @tt{∃a} binder and the equation, collapsing the term to
@tt{one{2}}.

@(step-pict first-path 9)

@section{Step 10 — ONE-VALUE}

@tt{one{2}} wraps a single concrete value, so @racket[ONE-VALUE] simply
unwraps it: @racket[(one 2)] reduces to @racket[2], matching §2.1 of the
paper.

@(step-pict first-path 10)

@section{Final check}

Whenever this manual is built, the path's final term is confirmed to be a
genuine normal form (no further reduction rule applies, via
@racket[must-be-stuck]); and @filepath{test/paths-test.rkt}
cross-checks the curated answer against @racket[run], which explores the
@emph{entire} reduction graph rather than following a single hand-picked
path.  Both must agree on @racket[2].

Why narrate one curated path rather than letting the stepper choose?  At
several points during this derivation the relation offers several legal moves
at once — for instance, either @tt{2=a} or @tt{5=b} could have been swapped
at Step 5, and at Step 6 either @racket[EQN-ELIM] on @tt{b=5} or @racket[HNF-SWAP] on @tt{2=a} would have been a legal move.  A greedy stepper can wander; this document therefore narrates one
instructive path while @racket[must-step] proves each step is a real edge of
the relation — see the opening-example section for the full story of why
greedy tracing can diverge.

The moral of this trace is that β-reduction in the Verse Calculus splits
"parameter passing" into a sequence of visible unification steps: the equation
@tt{p=⟨2,5⟩} introduced by @racket[APP-BETA] is not immediately substituted
but persists until unification propagates it.  Furthermore, the decomposition
reveals demand-driven evaluation: @racket[b]'s value @tt{5} was never needed
by the result and never moved anywhere, while @racket[a]'s value @tt{2} was
demanded by the result position and had to be explicitly substituted before
the binder could be eliminated.

@section{Exploring interactively}

To walk the full reduction graph in the Redex GUI, start a Racket REPL at the
repo root and evaluate:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,first-apply))
]
