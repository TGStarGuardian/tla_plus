-------------------------- MODULE SelectionSort --------------------------
EXTENDS SortProperties

CONSTANTS MaxLen, Elements
ASSUME MaxLen \in Nat /\ Elements \subseteq Int /\ IsFiniteSet(Elements)
ModelElements == {-1, 0, 1}
Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}

VARIABLES original, a, i, cursor, minimum, phase
vars == <<original, a, i, cursor, minimum, phase>>
N == Len(original)
Done == phase = "ready" /\ i >= N

Init ==
    /\ original \in Inputs /\ a = Identity(N)
    /\ i = 1 /\ cursor = 1 /\ minimum = 1 /\ phase = "ready"

Start ==
    /\ phase = "ready" /\ i < N
    /\ minimum' = i /\ cursor' = i + 1 /\ phase' = "scan"
    /\ UNCHANGED <<original, a, i>>

Compare ==
    /\ phase = "scan" /\ cursor <= N
    /\ minimum' = IF original[a[cursor]] < original[a[minimum]]
                  THEN cursor ELSE minimum
    /\ cursor' = cursor + 1
    /\ UNCHANGED <<original, a, i, phase>>

EndScan ==
    /\ phase = "scan" /\ cursor = N + 1 /\ phase' = "swap"
    /\ UNCHANGED <<original, a, i, cursor, minimum>>

Exchange ==
    /\ phase = "swap"
    /\ a' = IF minimum = i THEN a ELSE Swap(a, i, minimum)
    /\ i' = i + 1 /\ phase' = "ready"
    /\ UNCHANGED <<original, cursor, minimum>>

Next == Start \/ Compare \/ EndScan \/ Exchange \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs /\ a \in [1..N -> 1..N]
    /\ i \in 1..(N + 1) /\ cursor \in 1..(N + 1)
    /\ minimum \in 1..(N + 1) /\ phase \in {"ready", "scan", "swap"}
AccessSafety == phase # "ready" =>
    /\ i \in 1..(N - 1) /\ minimum \in i..N /\ cursor \in (i + 1)..(N + 1)
    /\ phase = "swap" => cursor = N + 1
PreservesElements == Permutation(a, Identity(N))
MinimumCorrect == phase # "ready" =>
    /\ minimum \in i..(cursor - 1)
    /\ \A k \in i..(cursor - 1) : original[a[minimum]] <= original[a[k]]
    /\ \A k \in i..(minimum - 1) : original[a[minimum]] < original[a[k]]
PrefixFinal == \A k \in 1..(i - 1) : FinalAt(Keys(a, original), k)
SortedAtEnd == Done => KeySorted(a, original)
Terminates == <>Done

\* Deliberately false for the separate expected-failure configuration.
StableAtEnd == Done => Stable(a, original)
WitnessSpec == (Init /\ original = <<1, 1, 0>>) /\ [][Next]_vars /\ WF_vars(Next)
=============================================================================
