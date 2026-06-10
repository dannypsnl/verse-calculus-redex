#lang scribble/manual
@(require "../traces/paths.rkt"
          "../trace-pict.rkt")

@title{Tracing §2.1: first⟨2,5⟩}

The paper's §2.1 defines @tt{first := λp. ∃a b. p=⟨a,b⟩; a} and applies it to
@tt{⟨2,5⟩}, returning the first component.

The headline is @racket[APP-BETA]: application does @emph{not} substitute the
argument into the body.  Instead β-reduction introduces a fresh @tt{∃p} and an
equation @tt{p=⟨2,5⟩} in front of the untouched body — application is
call-by-unification.  The rest of the trace is unification doing, one explicit
step at a time, what substitution would have done.  The result is @racket[2].

@(trace-pict first-path)

@section{Step 1 — APP-BETA}

@racket[APP-BETA] introduces a fresh existential for the parameter plus an
equation binding it to the argument, both in front of the original body:
@tt{∃p. p=⟨2,5⟩; ∃a. ∃b. p=⟨a,b⟩; a}.  The body is untouched; @tt{⟨2,5⟩} is not
copied in.  (The model picks the fresh name via @racket[variable-not-in]; the
curated term keeps @racket[p], α-equivalent to the model's choice.)

@(step-pict first-path 1)

@section{Step 2 — SUBST}

@tt{p=⟨2,5⟩} defines @racket[p] (side conditions hold: @racket[p] occurs in
@tt{p=⟨a,b⟩}; @tt{p ∉ fvs(⟨2,5⟩)}; the RHS is not a variable).  @racket[SUBST]
rewrites the occurrence of @racket[p] to give @tt{⟨2,5⟩=⟨a,b⟩}, keeping the
defining equation.

@(step-pict first-path 2)

@section{Step 3 — EQN-ELIM}

@racket[p] is now consumed; @racket[EQN-ELIM] removes @tt{p=⟨2,5⟩} and its
@tt{∃p} binder.

@(step-pict first-path 3)

@section{Step 4 — U-TUP}

@racket[U-TUP] decomposes @tt{⟨2,5⟩=⟨a,b⟩} componentwise into @tt{2=a; 5=b}.

@(step-pict first-path 4)

@section{Step 5 — HNF-SWAP}

@tt{5=b} has a literal on the left and a variable on the right; @racket[HNF-SWAP]
orients it to @tt{b=5}.  (@tt{2=a} is equally mis-oriented — either swap is
legal; the path picks @tt{5=b} first.)

@(step-pict first-path 5)

@section{Step 6 — EQN-ELIM}

@racket[b] is used nowhere else (the result is @racket[a]), so @racket[EQN-ELIM]
removes @tt{∃b} and @tt{b=5} — @emph{without the value 5 ever flowing anywhere}.
Contrast @racket[a], whose equation cannot go until its value reaches the result
position.

@(step-pict first-path 6)

@section{Step 7 — HNF-SWAP}

@racket[HNF-SWAP] flips the remaining @tt{2=a} to @tt{a=2}.

@(step-pict first-path 7)

@section{Step 8 — SUBST}

@tt{a=2} is solved; @racket[SUBST] propagates @racket[2] into the result
position.  The equation and @tt{∃a} binder remain for now.

@(step-pict first-path 8)

@section{Step 9 — EQN-ELIM}

@racket[a] is isolated; @racket[EQN-ELIM] removes @tt{∃a} and @tt{a=2}, leaving
@tt{one{2}}.

@(step-pict first-path 9)

@section{Step 10 — ONE-VALUE}

@racket[ONE-VALUE] unwraps @tt{one{2}} to @racket[2].

@(step-pict first-path 10)
