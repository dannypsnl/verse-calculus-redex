#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.2: residuation}

The paper's §2.2 example is the program

@verbatim{∃x y. y=7; x=add⟨3, y⟩; x}

The headline phenomenon is that the primitive call @tt{add⟨3,y⟩} is
@emph{stuck} at the start: the @racket[APP-ADD] rule only fires when
@emph{both} arguments are integer literals, and @racket[y] is still an
unknown at that point.  Functional-logic programs do not evaluate
left-to-right; instead, the call @emph{residuates} — it suspends in place
until unification has supplied enough information.  Here the equation
@tt{y=7} must act first: once it propagates @tt{7} into the suspended call,
the arithmetic can proceed.

Every figure below is generated from the Redex model when this manual is
built: the module that defines the curated path
(@filepath{traces/paths.rkt}) re-verifies each reduction step
against the model's @racket[vc-eval] relation (via @racket[must-step], up to
α-equivalence) whenever it is required, so the figures cannot silently drift
from the model.

The path starts from @racket[t0], which wraps the unwrapped program
exported from @filepath{programs.rkt} in @racket[(one _)], exactly as the
model's @racket[run] does: Fig 1 of the paper specifies that a program is evaluated
under @racket[one], which yields exactly one result or fails.

The full six-step path we will follow — each node shows the paper notation
above its s-expression form, and the gray @tt{↪} annotations list the
@emph{other} rules that could legally fire at that state, computed live from
the model:

@(trace-pict residuation-path)

@section{Step 1 — SUBST}

At @racket[t0] the primitive call @tt{add⟨3,y⟩} cannot fire because
@racket[y] is still unbound — @racket[APP-ADD] requires integer literals in
both argument positions.  The only productive move is to propagate the
equation @tt{y=7} into the rest of the sequence.  The side conditions for
@racket[SUBST] are satisfied: @racket[y] occurs free later in the sequence
(inside the suspended call), the right-hand side @racket[7] is not a
variable (so no variable-ordering constraint is triggered), and @racket[y]
does not appear in @racket[7] (no occurs-check violation).  This is
residuation in action: the call @tt{add⟨3,y⟩} cannot fire, but unification
can still make progress around it.  After the step, the suspended call has
become @tt{add⟨3,7⟩}.

@(step-pict residuation-path 1)

@section{Step 2 — EQN-ELIM}

The equation @tt{y=7} has done its job: after the substitution, @racket[y]
no longer occurs anywhere outside its defining equation — not in the call,
not in the result position, nowhere.  Because the variable is isolated,
@racket[EQN-ELIM] removes both the equation and the enclosing @tt{∃y}
binder together, leaving a cleaner term.

@(step-pict residuation-path 2)

@section{Step 3 — APP-ADD}

Now both arguments of the call are integer literals, so the suspended call
wakes up: @racket[APP-ADD] fires and @tt{add⟨3,7⟩} reduces to @racket[10].
@racket[APP-ADD] itself matches just the call @tt{add⟨3, 7⟩}; it reaches
inside the equation's right-hand side because the evaluator applies rules in
any subterm (the compatible closure of the rewrite rules).  The equation becomes @tt{x=10},
and @racket[x]'s binder is retained until the next steps clean it up.

@(step-pict residuation-path 3)

@section{Step 4 — SUBST}

With @tt{x=10} now fully solved, @racket[SUBST] propagates the value
@racket[10] into the result position: the trailing @racket[x] in the
sequence becomes @racket[10].  The defining equation @tt{x=10} and the
@tt{∃x} binder remain for now; they will be swept away in the next step.

@(step-pict residuation-path 4)

@section{Step 5 — EQN-ELIM}

@racket[x] no longer appears anywhere outside its defining equation
@tt{x=10}: the result position now holds the literal @racket[10].
@racket[EQN-ELIM] removes both the @tt{∃x} binder and the equation,
collapsing the term down to @tt{one{10}}.

@(step-pict residuation-path 5)

@section{Step 6 — ONE-VALUE}

@tt{one{10}} wraps a single concrete value, so @racket[ONE-VALUE] simply
unwraps it: @racket[(one 10)] reduces to @racket[10].

@(step-pict residuation-path 6)

@section{Final check}

Whenever this manual is built, the path's final term is confirmed to be a
genuine normal form (no further reduction rule applies, via
@racket[must-be-stuck]); and @filepath{test/paths-test.rkt}
cross-checks the curated answer against @racket[run], which explores the
@emph{entire} reduction graph rather than following a single hand-picked
path.  Both must agree on @racket[10].

Even in this small program the relation offers several legal moves at once
(@racket[EXI-SWAP] on the binders, or @racket[SUBST]), and a greedy stepper can
wander; this document therefore narrates one instructive path while
@racket[must-step] proves each step is a real edge of the relation — see the
opening-example section for the full story of why greedy tracing diverges.

The moral of this trace is that "evaluation order" in the Verse Calculus is
demand-driven by unification, not syntactic position: the equation @tt{y=7}
textually precedes @tt{add⟨3,y⟩} in the source, yet what makes the story
interesting is that the call was stuck and unification had to supply the
missing value before arithmetic could proceed — had the program been written
in the reverse order the same residuation behavior would occur, with the
arithmetic suspended until the equation reached it.

@section{Exploring interactively}

To walk the full reduction graph in the Redex GUI, start a Racket REPL at the
repo root and evaluate:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,residuation))
]
