#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.6: tuple indexing as choice}

Section 2.6 of the paper explains that applying a @emph{tuple} to an argument
means @emph{indexing}: @tt{⟨v0,v1,…,vn⟩(i)} looks up position @tt{i}.
Because @tt{i} is here an unconstrained existential, it ranges over every
valid index; and because the program sits under @tt{all{…}}, every result is
collected rather than committed to.  Consequently,
@tt{all{∃i. ⟨10,27,32⟩(i)}} @emph{enumerates} all three index positions and
gathers their results into a fresh tuple — reconstructing the original
@tt{⟨10,27,32⟩} from the outside in.

This is the richest trace in the series: 11 steps, covering application
(@racket[APP-TUP]), binder bookkeeping
(@racket[EXI-SWAP], @racket[VAR-SWAP], @racket[EQN-ELIM]),
choice distribution (@racket[CHOOSE], twice), three more eliminations
(@racket[EQN-ELIM] ×3), choice reification (@racket[ALL-CHOICE]),
and the outer unwrap (@racket[ONE-VALUE]).

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

The full eleven-step path we will follow — each node shows the paper
notation above its s-expression form, and the gray @tt{↪} annotations list
the @emph{other} rules that could legally fire at that state, computed live
from the model.  (The three-way choice that @racket[APP-TUP] builds —
@tt{x=0; 10 | x=1; 27 | x=2; 32}, right-nested in the model's
@racket[choose] representation — recurs verbatim through the first four
steps; @filepath{paths.rkt} names it once as @racket[tup-body].)

@(trace-pict tuple-indexing-path)

@section{Step 1 — APP-TUP}

Applying a @emph{tuple} to a value turns indexing into @emph{choice}.  The
@racket[APP-TUP] rule matches @tt{⟨v0,…,vn⟩(e)} and introduces a fresh
variable @racket[x] equated with the argument @tt{e}; the body (constructed
by the @racket[index-choices] metafunction) then offers one alternative per
index: @tt{x=0; v0}, @tt{x=1; v1}, …, @tt{x=n; vn}.  Here the three-element
tuple produces @tt{x=i; (x=0; 10 | x=1; 27 | x=2; 32)}.  Because @racket[i]
is an unconstrained existential ranging over all integers, no alternative is
ruled out at this stage — the choice is genuinely open.

@(step-pict tuple-indexing-path 1)

@section{Step 2 — EXI-SWAP}

To eliminate @racket[i] we need @tt{∃i} to sit @emph{directly above} the
equation @tt{x=i} that mentions it.  In the current term, however, @tt{∃i}
is on the outside and @tt{∃x} is on the inside — an execution context cannot
cross a binder, so @racket[EQN-ELIM] cannot yet reach the equation.
@racket[EXI-SWAP] permutes the two binders from @tt{∃i. ∃x. …} to
@tt{∃x. ∃i. …}, placing @tt{∃i} adjacent to @tt{x=i}.
(The equation's orientation is the second obstacle — Step 3 deals with it.)

This step is also the trace's cautionary tale: @racket[EXI-SWAP] is exactly
the rule that makes greedy tracing loop.  With two adjacent binders the rule
can swap in either direction, and a greedy stepper would swap back and forth
forever, never making progress.  The curated path uses @racket[EXI-SWAP]
exactly once, on purpose, to set up the elimination that follows.

@(step-pict tuple-indexing-path 2)

@section{Step 3 — VAR-SWAP}

@racket[EQN-ELIM] eliminates a binder @tt{∃y} only when the matching equation
has @tt{y} on the @emph{left}: @tt{y=e}.  The current equation is @tt{x=i},
so it is @racket[x] — not @racket[i] — that would be eliminated, which is
the wrong variable.  @racket[VAR-SWAP] flips @tt{x=i} to @tt{i=x}.  The rule's
side condition involves the variable order @racket[var<] — the model's
approximation of the paper's "bound inside" order; for two plain source names
it falls back to lexical order, and @tt{i} < @tt{x} lexically, so the flip
is legal.

@(step-pict tuple-indexing-path 3)

@section{Step 4 — EQN-ELIM}

With @tt{i=x} in place and @tt{∃i} directly above it, @racket[EQN-ELIM]
applies: @racket[i] does not appear anywhere else in the term (it is not free
in @racket[tup-body], and the scope of @tt{∃i} does not extend past the equation
sequence), so the binder and the equation are both removed together.  The
index variable is gone; what remains is @tt{∃x} scoping over the three-way
choice @racket[tup-body].

@(step-pict tuple-indexing-path 4)

@section{Step 5 — CHOOSE (first)}

The @racket[CHOOSE] rule has the shape
@tt{SX[CX[e1 | e2]] → SX[CX[e1] | CX[e2]]}, where @tt{SX} is a
@emph{scope} context (either @tt{one{…}} or @tt{all{…}}) and @tt{CX} is a
@emph{choice} context with @tt{CX ≠ ▢} (i.e., @tt{CX} is not the empty
context; there must be at least one layer between the scope and the
@tt{choose}).  Here the scope context is @tt{all{…}} and the choice context
is @tt{∃x. ▢} — a non-trivial context,
satisfying the side condition.  The rule distributes @tt{∃x} over the outermost
@tt{choose}, @emph{duplicating the binder} into each branch: the left split
becomes @tt{(∃x. x=0; 10)} and the right branch keeps the remaining two-way
choice @tt{(x=1; 27 | x=2; 32)} under its own fresh @tt{∃x}.

@(step-pict tuple-indexing-path 5)

@section{Step 6 — CHOOSE (second)}

The right branch still has @tt{∃x} scoping over a choice.  The same
@racket[CHOOSE] rule distributes once more, splitting @tt{(∃x. x=1; 27 | x=2; 32)}
into @tt{(∃x. x=1; 27) | (∃x. x=2; 32)}.  The choice is now a right-nested
spine of three self-contained alternatives, each with its own private copy of
the binder @racket[x].  The three branches are fully independent from this
point on.

@(step-pict tuple-indexing-path 6)

@section{Steps 7–9 — EQN-ELIM ×3}

In each branch, @tt{x=k} constrains a variable @racket[x] that does not appear
anywhere in the branch's result (the results are the literals @racket[10],
@racket[27], @racket[32]).  @racket[EQN-ELIM] therefore removes both the
equation and its binder.  The curated path eliminates the branches left to
right (steps 7, 8, 9); any order is equally valid here — this is genuine
non-determinism.  Confluence guarantees every order produces the same normal
form — and since @racket[run] in @filepath{test/paths-test.rkt}
explores the whole reduction graph, a divergent order would not escape notice.

@(step-pict tuple-indexing-path 7)

@(step-pict tuple-indexing-path 8)

@(step-pict tuple-indexing-path 9)

@section{Step 10 — ALL-CHOICE}

@tt{all{…}} over a right-nested choice of @emph{values} reifies the alternatives
into a tuple via the @racket[flat-choice] metafunction: @tt{all{10 | 27 | 32}}
reduces to @tt{⟨10, 27, 32⟩}.  Unlike @tt{one}, which commits to the first
surviving alternative, @tt{all} keeps @emph{every} solution — and that is
exactly what the enumeration was for.

@(step-pict tuple-indexing-path 10)

@section{Step 11 — ONE-VALUE}

The outer program wrapper @tt{one{⟨10,27,32⟩}} holds a single value — the
reconstructed tuple.  @racket[ONE-VALUE] unwraps it: @racket[(one (tup 10 27 32))]
reduces to @racket[(tup 10 27 32)].  The answer is the original tuple, arrived
at by enumerating all of its indices from the outside in.

@(step-pict tuple-indexing-path 11)

@section{Final check}

Whenever this manual is built, the path's final term is confirmed to be a
genuine normal form (no further reduction rule applies, via
@racket[must-be-stuck]); and @filepath{test/paths-test.rkt}
cross-checks the curated answer against @racket[run], which explores the
@emph{entire} reduction graph rather than following a single hand-picked
path.  Both must agree on @racket[(tup 10 27 32)].

Why narrate a curated path at all?  Two places in this trace make the choice
vivid.  First, after step 2's state, @racket[EXI-SWAP] could ping-pong
forever — swapping @tt{∃x ∃i} back to @tt{∃i ∃x} and then forward again,
never terminating.  Second, at the three-elimination phase (steps 7–9),
@racket[EQN-ELIM] could fire in any of six orders; @racket[must-step] pins
down one instructive left-to-right path, but @racket[run] verifies that every
order reaches the same answer.

The moral of this trace: this example exercises every rule @emph{group} of the
model except failure — application (@racket[APP-TUP]), unification and swapping
(@racket[EXI-SWAP], @racket[VAR-SWAP]), elimination (@racket[EQN-ELIM]),
choice distribution (@racket[CHOOSE]), normalization (@racket[ALL-CHOICE]),
and the outer unwrap (@racket[ONE-VALUE]).  Failure and its interaction with
@tt{choose} and @tt{one} are covered in the if/then/else section.

@section{Exploring interactively}

To walk the full reduction graph in the Redex GUI, start a Racket REPL at the
repo root and evaluate:

@racketblock[
(require verse-calculus-redex/traces/programs
         verse-calculus-redex/stepper)
(trace `(one ,tuple-indexing))
]

The GUI graph here is genuinely branchy and worth a look: the three independent
@racket[EQN-ELIM] branches in steps 7–9 each produce their own fork,
and @racket[EXI-SWAP]'s ping-pong potential is visible as a two-node cycle
near the start of the graph.
