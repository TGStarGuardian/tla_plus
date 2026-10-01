---------------------------- MODULE MergeSort ----------------------------
EXTENDS SortProperties

CONSTANTS MaxLen, Elements
ASSUME MaxLen \in Nat /\ Elements \subseteq Int /\ IsFiniteSet(Elements)
ModelElements == {-1, 0, 1}
Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}

VARIABLES original, a, buffer, source, width, lo, mid, hi,
          left, right, out, chosen, copy, phase
vars == <<original, a, buffer, source, width, lo, mid, hi,
          left, right, out, chosen, copy, phase>>
N == Len(original)
Done == phase = "ready" /\ width >= N
\* During copy-back the completed buffer chunk owns the live identities.
Live == IF phase = "copy"
        THEN [k \in 1..N |-> IF k \in Indices(lo, hi) THEN buffer[k] ELSE a[k]]
        ELSE a

Init ==
    /\ original \in Inputs /\ a = Identity(N)
    /\ buffer = a /\ source = a
    /\ width = 1 /\ lo = 1 /\ mid = 1 /\ hi = 1
    /\ left = 1 /\ right = 1 /\ out = 1 /\ chosen = 1 /\ copy = 1
    /\ phase = "ready"

BeginMerge ==
    /\ phase = "ready" /\ width < N /\ lo <= N
    /\ mid' = lo + Min(width, N + 1 - lo)
    /\ hi' = mid' + Min(width, N + 1 - mid')
    /\ left' = lo /\ right' = mid' /\ out' = lo
    /\ source' = a /\ phase' = "compare"
    /\ UNCHANGED <<original, a, buffer, width, lo, chosen, copy>>

Compare ==
    /\ phase = "compare" /\ out < hi
    /\ chosen' = IF left < mid THEN
                     IF right = hi THEN left
                     ELSE IF original[a[left]] <= original[a[right]] THEN left ELSE right
                 ELSE right
    /\ phase' = "write"
    /\ UNCHANGED <<original, a, buffer, source, width, lo, mid, hi,
                   left, right, out, copy>>

Write ==
    /\ phase = "write"
    /\ buffer' = [buffer EXCEPT ![out] = a[chosen]]
    /\ left' = IF chosen < mid THEN left + 1 ELSE left
    /\ right' = IF chosen < mid THEN right ELSE right + 1
    /\ out' = out + 1 /\ phase' = "compare"
    /\ UNCHANGED <<original, a, source, width, lo, mid, hi, chosen, copy>>

BeginCopy ==
    /\ phase = "compare" /\ out = hi
    /\ copy' = lo /\ phase' = "copy"
    /\ UNCHANGED <<original, a, buffer, source, width, lo, mid, hi,
                   left, right, out, chosen>>

Copy ==
    /\ phase = "copy"
    /\ a' = [a EXCEPT ![copy] = buffer[copy]] /\ copy' = copy + 1
    /\ phase' = IF copy + 1 = hi THEN "ready" ELSE "copy"
    /\ lo' = IF copy + 1 = hi THEN hi ELSE lo
    /\ UNCHANGED <<original, buffer, source, width, mid, hi,
                   left, right, out, chosen>>

NextPass ==
    /\ phase = "ready" /\ width < N /\ lo = N + 1
    /\ width' = IF width >= N - width THEN N ELSE 2 * width
    /\ lo' = 1
    /\ UNCHANGED <<original, a, buffer, source, mid, hi,
                   left, right, out, chosen, copy, phase>>

Next == BeginMerge \/ Compare \/ Write \/ BeginCopy \/ Copy \/ NextPass
        \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs
    /\ a \in [1..N -> 1..N] /\ buffer \in [1..N -> 1..N]
    /\ source \in [1..N -> 1..N]
    /\ width \in 1..(N + 1)
    /\ lo \in 1..(N + 1) /\ mid \in 1..(N + 1) /\ hi \in 1..(N + 1)
    /\ left \in 1..(N + 1) /\ right \in 1..(N + 1) /\ out \in 1..(N + 1)
    /\ chosen \in 1..(N + 1) /\ copy \in 1..(N + 1)
    /\ phase \in {"ready", "compare", "write", "copy"}

MergeShape == phase # "ready" =>
    /\ lo < mid /\ mid <= hi /\ hi <= N + 1
    /\ lo <= left /\ left <= mid /\ mid <= right /\ right <= hi
    /\ out = lo + (left - lo) + (right - mid)
    /\ StableSorted(SubSeq(source, lo, mid - 1), original)
    /\ StableSorted(SubSeq(source, mid, hi - 1), original)
    /\ \A x \in Indices(lo, mid), y \in Indices(mid, hi) :
        original[source[x]] = original[source[y]] => source[x] < source[y]

AccessSafety ==
    /\ phase = "write" =>
        /\ out \in Indices(lo, hi) /\ chosen \in Indices(lo, hi)
        /\ (chosen = left /\ left < mid) \/ (chosen = right /\ right < hi)
    /\ phase = "compare" /\ out < hi => left < mid \/ right < hi
    /\ phase = "copy" => copy \in Indices(lo, hi) /\ out = hi

ArrayFrame == phase # "ready" =>
    IF phase = "copy" THEN
        /\ \A k \in Indices(lo, copy) : a[k] = buffer[k]
        /\ \A k \in (DOMAIN a) \ Indices(lo, copy) : a[k] = source[k]
    ELSE a = source

PreservesElements == Permutation(Live, Identity(N))
StableOrder == Stable(Live, original)

\* Already merged blocks have width 2*width; remaining runs have width width.
RunInvariant ==
    /\ RunsSorted(SubSeq(Live, 1, lo - 1), original, 2 * width)
    /\ RunsSorted(SubSeq(Live, lo, N), original, width)

MergePrefix == phase # "ready" =>
    LET prefix == SubSeq(buffer, lo, out - 1)
        consumed == SubSeq(source, lo, left - 1) \o SubSeq(source, mid, right - 1)
        remaining == Indices(left, mid) \cup Indices(right, hi)
    IN /\ Permutation(prefix, consumed)
       /\ StableSorted(prefix, original)
       /\ \A k \in DOMAIN prefix, r \in remaining : Before(prefix[k], source[r], original)

SortedAtEnd == Done => StableSorted(a, original)
Terminates == <>Done
=============================================================================
