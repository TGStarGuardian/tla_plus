---------------------------- MODULE BubbleSort ----------------------------
EXTENDS SortProperties

CONSTANTS MaxLen, Elements
ASSUME MaxLen \in Nat /\ Elements \subseteq Int /\ IsFiniteSet(Elements)
ModelElements == {-1, 0, 1}
Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}

VARIABLES original, a, bound, i, swapped, phase
vars == <<original, a, bound, i, swapped, phase>>
N == Len(original)
Done == phase = "done"

Init ==
    /\ original \in Inputs /\ a = Identity(N)
    /\ bound = N /\ i = 1 /\ swapped = FALSE /\ phase = "ready"

Start ==
    /\ phase = "ready" /\ bound > 1
    /\ i' = 1 /\ swapped' = FALSE /\ phase' = "compare"
    /\ UNCHANGED <<original, a, bound>>
Compare ==
    /\ phase = "compare"
    /\ phase' = IF original[a[i]] > original[a[i + 1]] THEN "swap" ELSE "advance"
    /\ UNCHANGED <<original, a, bound, i, swapped>>
Exchange ==
    /\ phase = "swap" /\ a' = Swap(a, i, i + 1)
    /\ swapped' = TRUE /\ phase' = "advance"
    /\ UNCHANGED <<original, bound, i>>
Advance ==
    /\ phase = "advance" /\ i' = i + 1
    /\ phase' = IF i + 1 = bound THEN "finish" ELSE "compare"
    /\ UNCHANGED <<original, a, bound, swapped>>
Finish ==
    /\ phase = "finish"
    /\ bound' = IF swapped THEN bound - 1 ELSE bound
    /\ phase' = IF swapped THEN "ready" ELSE "done"
    /\ UNCHANGED <<original, a, i, swapped>>
Stop ==
    /\ phase = "ready" /\ bound <= 1 /\ phase' = "done"
    /\ UNCHANGED <<original, a, bound, i, swapped>>
Next == Start \/ Compare \/ Exchange \/ Advance \/ Finish \/ Stop
        \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs /\ a \in [1..N -> 1..N]
    /\ bound \in 0..N /\ i \in 1..(N + 1) /\ swapped \in BOOLEAN
    /\ phase \in {"ready", "compare", "swap", "advance", "finish", "done"}
AccessSafety ==
    /\ phase \in {"compare", "swap", "advance"} => 1 <= i /\ i < bound
    /\ phase = "swap" => original[a[i]] > original[a[i + 1]]
    /\ phase = "finish" => i = bound /\ bound > 1
PreservesElements == Permutation(a, Identity(N))
StableOrder == Stable(a, original)
SuffixFinal == \A k \in (bound + 1)..N : FinalAt(Keys(a, original), k)
ScanMaximum ==
    /\ phase \in {"compare", "swap", "finish"} =>
        \A k \in 1..i : original[a[k]] <= original[a[i]]
    /\ phase = "advance" =>
        \A k \in 1..(i + 1) : original[a[k]] <= original[a[i + 1]]
PassFinal == phase = "finish" => FinalAt(Keys(a, original), bound)
NoSwapsSorted == phase = "finish" /\ ~swapped => KeySorted(a, original)
SortedAtEnd == Done => StableSorted(a, original)
Terminates == <>Done
=============================================================================
