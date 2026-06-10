#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.5: if/then/else, both branches}

Section 2.5 of the paper explains that the Verse Calculus has no built-in
boolean type or conditional expression.  Instead, @tt{if e then e2 else e3}
is desugared into @tt{one{(one{e; e2}) | e3}}: a committed-choice expression
wrapping a choice between the inner @tt{one} (which runs the condition followed
by the then-payload) and the else-expression @tt{e3}.

The key insight is that @tt{one} turns success-or-failure into a committed
decision.  The inner @tt{one{e; e2}} runs the condition; if the condition
succeeds, the sequence continues to @tt{e2} and the inner @tt{one} unwraps
the result.  If the condition fails, the entire inner @tt{one} produces @tt{fail}.
The outer @tt{one} then sees a choice of @tt{fail | e3} and, by the rule for
failure in a choice, reduces to @tt{one{e3}}, selecting the else-branch.

This document traces two closed instances:
@itemlist[
  @item{The @bold{true branch}: condition @tt{1=1} (two identical literals),
        then-payload @tt{10}, else-payload @tt{20}.  Result: @racket[10].}
  @item{The @bold{false branch}: condition @tt{1=2} (two different literals),
        then-payload @tt{10}, else-payload @tt{20}.  Result: @racket[20].}
]

The false-branch trace is where @tt{fail} as a first-class outcome shows up
most clearly: it is not a run-time error but an ordinary value that discards
its continuation and propagates outward through @tt{one} and @tt{choose} until
the calculus can route around it.

Every figure below is generated from the Redex model when this manual is
built: the module that defines the curated paths
(@filepath{traces/paths.rkt}) re-verifies each reduction step
against the model's @racket[vc-eval] relation (via @racket[must-step], up to
α-equivalence) whenever it is required, so the figures cannot silently drift
from the model.

Each trace starts from the corresponding unwrapped program exported from
@filepath{programs.rkt}, wrapped in @racket[(one _)] exactly as the model's
@racket[run] does: Fig 1 of the paper specifies that a program is evaluated
under @racket[one], which yields exactly one result or fails.

@section{The true branch}

The full three-step path for the true branch — gray @tt{↪} annotations list
the other legal moves at each state, computed live from the model:

@(trace-pict if-true-path)

@subsection{Step 1 — U-LIT}

The condition @tt{1=1} equates two identical integer literals.  The
@racket[U-LIT] rule applies when both sides of an equation are the same
literal: the trivially-true equation is consumed and the sequence continues
to its payload, @tt{10}.  The redex is the whole sequence @tt{1=1; 10} sitting
inside the inner @tt{one{...}} and the left arm of the outer @tt{choose}; the
evaluator (compatible closure) reaches it there.

Contrast with the false branch: with the different literals @tt{1} and @tt{2},
this same position would fail rather than succeed — see below.

@(step-pict if-true-path 1)

@subsection{Step 2 — ONE-VALUE}

The inner @tt{one{10}} now holds a single value — the integer @racket[10].
The @racket[ONE-VALUE] rule simply unwraps it: @tt{one{10}} reduces to
@tt{10}, exposing the value as the left alternative of the outer choice.

@(step-pict if-true-path 2)

@subsection{Step 3 — ONE-CHOICE}

The outer @tt{one} sees a choice @tt{10 | 20} whose leftmost alternative is
already a value.  The @racket[ONE-CHOICE] rule applies: it commits to @tt{10}
and @emph{discards @tt{20} unevaluated}.  This commitment is what makes
@tt{if/then/else} deterministic — once the condition succeeds and the
then-branch has a value, the else-branch is thrown away entirely.

@(step-pict if-true-path 3)

@section{The false branch}

The full four-step path for the false branch:

@(trace-pict if-false-path)

@subsection{Step 1 — U-FAIL}

The condition @tt{1=2} equates two @emph{different} integer literals.  The
@racket[hnf-clash?] metafunction detects that the heads clash, and @racket[U-FAIL]
fires: the entire sequence @tt{1=2; 10} rewrites to @tt{fail}.  The
then-payload @tt{10} is wiped out along with the failing condition — failure
is not an error but an ordinary outcome that discards its continuation.

@(step-pict if-false-path 1)

@subsection{Step 2 — ONE-FAIL}

The inner @tt{one{fail}} holds only @tt{fail}.  The @racket[ONE-FAIL] rule
propagates the failure out of the inner wrapper: @tt{one{fail}} reduces to
@tt{fail}, making the failure visible as the left alternative of the outer
choice.

@(step-pict if-false-path 2)

@subsection{Step 3 — CHOOSE-R}

The outer @tt{one} now contains a choice whose left alternative has failed.
The @racket[CHOOSE-R] rule reduces a choice @tt{fail | e3} to just @tt{e3}:
the failed alternative is discarded, and only the right-hand alternative
remains.  This is precisely how "else" gets selected — the failing left
branch clears the path for the right branch.

@(step-pict if-false-path 3)

@subsection{Step 4 — ONE-VALUE}

@tt{one{20}} holds a single value.  @racket[ONE-VALUE] unwraps it:
@racket[(one 20)] reduces to @racket[20].

@(step-pict if-false-path 4)

@section{Final check}

Whenever this manual is built, both paths' final terms are confirmed to be
genuine normal forms (no further reduction rule applies, via
@racket[must-be-stuck]); and @filepath{test/paths-test.rkt}
cross-checks both curated answers against @racket[run], which explores the
@emph{entire} reduction graph rather than following a single hand-picked
path.  They must agree on @racket[10] and @racket[20] respectively.

Why narrate curated paths rather than letting a stepper choose?  These two
derivations happen to be fully deterministic — at every intermediate state
exactly one rule applies — so here @racket[must-step] is verifying that
determinism rather than picking among alternatives. Other examples are not so
tame; see the opening-example section for why greedy tracing diverges in
general.

The moral of this trace: the §2.5 desugaring needs @emph{two} @tt{one}
wrappers.  The inner @tt{one{e; e2}} makes the condition's success or failure
decisive: even a condition with many solutions yields just one value (or
@tt{fail}).  The outer @tt{one} then commits to the first surviving
alternative of the @tt{choose}, turning success into the then-answer and
failure into the trigger that routes to the else-branch.  @tt{fail} and
@tt{choose} together give you @tt{else} for free — no conditional construct
is needed in the core calculus.

@section{Exploring interactively}

To walk the full reduction graph in the Redex GUI, start a Racket REPL at the
repo root and evaluate:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,if-true))
]

Swap @racket[if-true] for @racket[if-false] to see the false branch's
reduction graph, including the @tt{fail} propagation path.
