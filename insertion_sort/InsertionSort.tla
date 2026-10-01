-------------------------- MODULE InsertionSort --------------------------
EXTENDS SortProperties

CONSTANTS MaxLen, Elements
ASSUME MaxLen \in Nat /\ Elements \subseteq Int /\ IsFiniteSet(Elements)
ModelElements == {-1, 0, 1}
Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}

\* a and key hold original-index identities; original maps identities to values.
VARIABLES original, a, i, j, key, phase
vars == <<original, a, i, j, key, phase>>
N == Len(original)
Live == IF phase = "ready" THEN a ELSE [a EXCEPT ![j] = key]
Done == phase = "ready" /\ i > N

Init ==
    /\ original \in Inputs /\ a = Identity(N)
    /\ i = IF N = 0 THEN 1 ELSE 2
    /\ j = 1 /\ key = 0 /\ phase = "ready"

Load ==
    /\ phase = "ready" /\ i <= N
    /\ key' = a[i] /\ j' = i /\ phase' = "compare"
    /\ UNCHANGED <<original, a, i>>

Compare ==
    /\ phase = "compare"
    /\ phase' = IF j > 1 THEN
                    IF original[a[j - 1]] > original[key] THEN "shift" ELSE "place"
                ELSE "place"
    /\ UNCHANGED <<original, a, i, j, key>>

Shift ==
    /\ phase = "shift"
    /\ a' = [a EXCEPT ![j] = a[j - 1]] /\ j' = j - 1
    /\ phase' = "compare"
    /\ UNCHANGED <<original, i, key>>

Place ==
    /\ phase = "place"
    /\ a' = [a EXCEPT ![j] = key] /\ i' = i + 1 /\ phase' = "ready"
    /\ UNCHANGED <<original, j, key>>

Next == Load \/ Compare \/ Shift \/ Place \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs /\ a \in [1..N -> 1..N]
    /\ i \in 1..(N + 1) /\ j \in 1..(N + 1) /\ key \in 0..N
    /\ phase \in {"ready", "compare", "shift", "place"}

AccessSafety ==
    /\ phase # "ready" =>
        /\ i \in 2..N /\ j \in 1..i /\ key \in 1..N
    /\ phase = "shift" => j > 1 /\ original[a[j - 1]] > original[key]

PreservesElements == Permutation(Live, Identity(N))
StableOrder == Stable(Live, original)
PrefixCorrect == phase = "ready" =>
    /\ StableSorted(SubSeq(a, 1, i - 1), original)
    /\ Permutation(SubSeq(a, 1, i - 1), Identity(i - 1))
    /\ \A k \in i..N : a[k] = k

ShiftInvariant == phase # "ready" =>
    /\ key = i
    /\ StableSorted(SubSeq(a, 1, j - 1) \o SubSeq(a, j + 1, i), original)
    /\ \A k \in (j + 1)..i : original[a[k]] > original[key]
    /\ Permutation(SubSeq(Live, 1, i), Identity(i))
    /\ \A k \in (i + 1)..N : a[k] = k
    /\ phase = "place" =>
        IF j > 1 THEN original[a[j - 1]] <= original[key] ELSE TRUE

SortedAtEnd == Done => StableSorted(a, original)
Terminates == <>Done
=============================================================================
