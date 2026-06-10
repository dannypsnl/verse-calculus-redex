#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.6: tuple indexing as choice}

Applying a @emph{tuple} to an argument means @emph{indexing}:
@tt{⟨v0,…,vn⟩(i)} looks up position @tt{i}.  With @tt{i} an unconstrained
existential it ranges over every valid index, and under @tt{all{…}} every
result is collected.  So @tt{all{∃i. ⟨10,27,32⟩(i)}} enumerates all three
positions and gathers them into a fresh tuple — reconstructing
@tt{⟨10,27,32⟩} from the outside in.

This is the richest trace: 11 steps exercising every rule group except
failure — @racket[APP-TUP], @racket[EXI-SWAP], @racket[VAR-SWAP],
@racket[EQN-ELIM], @racket[CHOOSE], @racket[ALL-CHOICE], and @racket[ONE-VALUE].
The three-way choice @racket[APP-TUP] builds (@tt{x=0; 10 | x=1; 27 | x=2; 32},
right-nested in the model's @racket[choose]) recurs through the first four
steps; @filepath{paths.rkt} names it @racket[tup-body].

@(trace-pict tuple-indexing-path)

@section{Step 1 — APP-TUP}

@racket[APP-TUP] turns indexing into choice: it introduces a fresh @racket[x]
equated with the argument, and (via @racket[index-choices]) a body offering one
alternative per index.  Here that is @tt{x=i; (x=0; 10 | x=1; 27 | x=2; 32)};
since @racket[i] is unconstrained, no alternative is ruled out.

@(step-pict tuple-indexing-path 1)

@section{Step 2 — EXI-SWAP}

To eliminate @racket[i], @tt{∃i} must sit directly above the equation @tt{x=i}
(an execution context cannot cross a binder).  @racket[EXI-SWAP] permutes
@tt{∃i. ∃x. …} to @tt{∃x. ∃i. …}.  This is also the rule that makes greedy
tracing loop — two adjacent binders can swap back and forth forever; the path
uses it exactly once, on purpose.

@(step-pict tuple-indexing-path 2)

@section{Step 3 — VAR-SWAP}

@racket[EQN-ELIM] eliminates @tt{∃y} only when the equation has @tt{y} on the
left.  The equation is @tt{x=i}, so @racket[VAR-SWAP] flips it to @tt{i=x}.  Its
side condition uses @racket[var<] (the model's approximation of the paper's
"bound inside" order); for plain source names it falls back to lexical order,
and @tt{i < x}.

@(step-pict tuple-indexing-path 3)

@section{Step 4 — EQN-ELIM}

With @tt{i=x} under @tt{∃i} and @racket[i] free nowhere else, @racket[EQN-ELIM]
removes the binder and equation together.  What remains is @tt{∃x} scoping the
three-way choice @racket[tup-body].

@(step-pict tuple-indexing-path 4)

@section{Step 5 — CHOOSE (first)}

@racket[CHOOSE] has the shape @tt{SX[CX[e1 | e2]] → SX[CX[e1] | CX[e2]]}, with
@tt{SX} a scope context (@tt{one{…}}/@tt{all{…}}) and @tt{CX ≠ ▢} a choice
context.  Here @tt{SX = all{…}} and @tt{CX = ∃x. ▢}, so the rule distributes
@tt{∃x} over the outermost @tt{choose}, @emph{duplicating the binder}: the left
split becomes @tt{(∃x. x=0; 10)} and the right keeps @tt{(x=1; 27 | x=2; 32)}
under its own @tt{∃x}.

@(step-pict tuple-indexing-path 5)

@section{Step 6 — CHOOSE (second)}

@racket[CHOOSE] distributes once more, splitting the right branch into three
independent alternatives, each with its own private @racket[x].

@(step-pict tuple-indexing-path 6)

@section{Steps 7–9 — EQN-ELIM ×3}

In each branch @tt{x=k} constrains an @racket[x] absent from the branch's result
(@racket[10], @racket[27], @racket[32]), so @racket[EQN-ELIM] removes equation
and binder.  The path eliminates left to right; any order is valid here, and
confluence (cross-checked by @racket[run]) guarantees the same normal form.

@(step-pict tuple-indexing-path 7)

@(step-pict tuple-indexing-path 8)

@(step-pict tuple-indexing-path 9)

@section{Step 10 — ALL-CHOICE}

@racket[ALL-CHOICE] reifies a right-nested choice of @emph{values} into a tuple
(via @racket[flat-choice]): @tt{all{10 | 27 | 32}} reduces to @tt{⟨10, 27, 32⟩}.
Unlike @tt{one}, @tt{all} keeps every solution.

@(step-pict tuple-indexing-path 10)

@section{Step 11 — ONE-VALUE}

@racket[ONE-VALUE] unwraps @tt{one{⟨10,27,32⟩}} to @racket[(tup 10 27 32)] — the
original tuple, rebuilt by enumerating its indices.

@(step-pict tuple-indexing-path 11)
