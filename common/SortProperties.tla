-------------------------- MODULE SortProperties --------------------------
EXTENDS Integers, Sequences, FiniteSets

Indices(lo, hi) == lo..(hi - 1)

Swap(a, i, j) == [a EXCEPT ![i] = a[j], ![j] = a[i]]

Values(a) == {a[k] : k \in DOMAIN a}
Count(a, v) == Cardinality({k \in DOMAIN a : a[k] = v})
Permutation(a, b) ==
    /\ Len(a) = Len(b)
    /\ \A v \in Values(a) \cup Values(b) : Count(a, v) = Count(b, v)

Sorted(a) == \A i, j \in DOMAIN a : i < j => a[i] <= a[j]

\* A final position has a value compatible with a sorted permutation of a.
FinalAt(a, k) ==
    /\ \A j \in 1..(k - 1) : a[j] <= a[k]
    /\ \A j \in (k + 1)..Len(a) : a[k] <= a[j]


Min(x, y) == IF x < y THEN x ELSE y
Identity(n) == [k \in 1..n |-> k]
Keys(order, original) == [k \in DOMAIN order |-> original[order[k]]]
KeySorted(order, original) == Sorted(Keys(order, original))
Stable(order, original) ==
    \A i, j \in DOMAIN order :
        (i < j /\ original[order[i]] = original[order[j]]) => order[i] < order[j]
StableSorted(order, original) == KeySorted(order, original) /\ Stable(order, original)
Before(x, y, original) ==
    original[x] < original[y] \/ (original[x] = original[y] /\ x <= y)
RunsSorted(order, original, width) ==
    \A b \in DOMAIN order : (b - 1) % width = 0 =>
        StableSorted(SubSeq(order, b, Min(b + width - 1, Len(order))), original)
=============================================================================
