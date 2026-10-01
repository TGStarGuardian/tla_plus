----------------------------- MODULE HeapSort -----------------------------
EXTENDS SortProperties

CONSTANTS MaxLen, Elements
ASSUME MaxLen \in Nat /\ Elements \subseteq Int /\ IsFiniteSet(Elements)
ModelElements == {-1, 0, 1}
Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}

VARIABLES original, a, size, build, root, hole, saved, child, mode, phase
vars == <<original, a, size, build, root, hole, saved, child, mode, phase>>
N == Len(original)
Children(p) == {2 * p, 2 * p + 1} \cap (1..size)
Live == IF phase = "ready" THEN a ELSE [a EXCEPT ![hole] = saved]
OrderedAt(order, p) ==
    \A c \in Children(p) : original[order[p]] >= original[order[c]]
Heap(order) == \A p \in 1..size : OrderedAt(order, p)
Done == mode = "sort" /\ phase = "ready" /\ size <= 1

Init ==
    /\ original \in Inputs /\ a = Identity(N)
    /\ size = N /\ build = N \div 2
    /\ root = 1 /\ hole = 1 /\ child = 1 /\ saved = 0
    /\ mode = "build" /\ phase = "ready"
StartBuild ==
    /\ mode = "build" /\ phase = "ready" /\ build > 0
    /\ root' = build /\ hole' = build /\ saved' = a[build]
    /\ phase' = "children"
    /\ UNCHANGED <<original, a, size, build, child, mode>>
Built ==
    /\ mode = "build" /\ phase = "ready" /\ build = 0
    /\ mode' = "sort"
    /\ UNCHANGED <<original, a, size, build, root, hole, saved, child, phase>>
Extract ==
    /\ mode = "sort" /\ phase = "ready" /\ size > 1
    /\ a' = Swap(a, 1, size) /\ size' = size - 1
    /\ root' = 1 /\ hole' = 1 /\ saved' = a[size]
    /\ phase' = "children"
    /\ UNCHANGED <<original, build, child, mode>>
FindChildren ==
    /\ phase = "children"
    /\ child' = IF hole <= size \div 2 THEN 2 * hole ELSE child
    /\ phase' = IF hole <= size \div 2 THEN "select" ELSE "place"
    /\ UNCHANGED <<original, a, size, build, root, hole, saved, mode>>
SelectChild ==
    /\ phase = "select"
    /\ child' = IF child < size THEN
                    IF original[a[child]] < original[a[child + 1]] THEN child + 1 ELSE child
                ELSE child
    /\ phase' = "compare"
    /\ UNCHANGED <<original, a, size, build, root, hole, saved, mode>>
Compare ==
    /\ phase = "compare"
    /\ phase' = IF original[saved] >= original[a[child]] THEN "place" ELSE "move"
    /\ UNCHANGED <<original, a, size, build, root, hole, saved, child, mode>>
Move ==
    /\ phase = "move" /\ a' = [a EXCEPT ![hole] = a[child]]
    /\ hole' = child /\ phase' = "children"
    /\ UNCHANGED <<original, size, build, root, saved, child, mode>>
Place ==
    /\ phase = "place" /\ a' = [a EXCEPT ![hole] = saved]
    /\ build' = IF mode = "build" THEN build - 1 ELSE build
    /\ phase' = "ready"
    /\ UNCHANGED <<original, size, root, hole, saved, child, mode>>
Next == StartBuild \/ Built \/ Extract \/ FindChildren \/ SelectChild
        \/ Compare \/ Move \/ Place \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs /\ a \in [1..N -> 1..N]
    /\ size \in 0..N /\ build \in 0..(N \div 2)
    /\ root \in 1..(N + 1) /\ hole \in 1..(N + 1)
    /\ saved \in 0..N /\ child \in 1..(N + 1)
    /\ mode \in {"build", "sort"}
    /\ phase \in {"ready", "children", "select", "compare", "move", "place"}
AccessSafety ==
    /\ mode = "build" => size = N
    /\ phase # "ready" =>
        /\ root \in 1..size /\ hole \in root..size /\ saved \in 1..N
        /\ mode = "build" => build = root /\ build > 0
    /\ phase = "select" => child = 2 * hole /\ child \in 1..size
    /\ phase \in {"compare", "move"} => child \in Children(hole)
PreservesElements == Permutation(Live, Identity(N))
BuiltSubtrees == mode = "build" /\ phase = "ready" =>
    \A p \in (build + 1)..size : OrderedAt(a, p)
HeapAtBoundary == mode = "sort" /\ phase = "ready" => Heap(a)
RepairInvariant == phase # "ready" =>
    /\ \A p \in root..size : p # hole => OrderedAt(Live, p)
    \* The hole's parent can safely accept either of the hole's children.
    /\ hole # root =>
        \A c \in Children(hole) : original[Live[hole \div 2]] >= original[Live[c]]
ChildCorrect == phase \in {"compare", "move"} =>
    /\ \A c \in Children(hole) : original[a[child]] >= original[a[c]]
    /\ child = 2 * hole + 1 => original[a[child]] > original[a[child - 1]]
    /\ phase = "move" => original[a[child]] > original[saved]
ReadyToPlace == phase = "place" => OrderedAt(Live, hole)
SuffixFinal == \A k \in (size + 1)..N : FinalAt(Keys(Live, original), k)
SortedAtEnd == Done => KeySorted(a, original)
Terminates == <>Done

\* Extracting from two equal elements reverses their identities.
StableAtEnd == Done => Stable(a, original)
WitnessSpec == (Init /\ original = <<0, 0>>) /\ [][Next]_vars /\ WF_vars(Next)
=============================================================================
