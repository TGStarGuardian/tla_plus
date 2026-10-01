# Heap sort

`heap_sort.hpp` builds a max-heap bottom-up, then repeatedly exchanges its root
with the last heap element and repairs the shortened heap. The iterative repair
saves one value and moves larger children upward through a temporary hole.
It selects the left child on equality and stops when the saved value is at
least the larger child. `HeapSort.tla` models child selection, comparison with
the saved value, each upward move, placement, and extraction.

```cpp
#include "heap_sort/heap_sort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
heap_sort::sort(values);
```

Run `make test` and
`make heap-model TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar` from the repository
root. See [shared verification conventions](../common/README.md) for identity
semantics, complete results, and the limits of bounded checking.

## General correctness argument

Use one-based heap indices here, matching TLA+: the children of node `p` are
`2p` and `2p+1`, when at most `size`. Max-heap order requires each parent value
to be at least its children's values. By following parent links, the root of
a max-heap is therefore a maximum of the entire heap.

### Saved-value repair

Repair begins at `root`, with both child subtrees already heaps. Save the root
identity and regard its array position as a hole. `Live` replaces that hole
with the saved identity; `Permutation(Live, Identity(n))` expresses preservation
even while physical array entries contain duplicates.

Among all processed parent indices `p >= root`, every heap edge except those
leaving the hole is ordered. If the hole has moved below the repair root, its
parent also dominates each of the hole's children. These two facts form
`RepairInvariant`; the second fact allows a child to move upward without
violating the edge above the hole. Initially the hole is the root, so that
additional condition is vacuous.

If there is no child, place the saved value. Otherwise choose a maximum child,
breaking equal ties toward the left (`ChildCorrect`). If the saved value is at
least that child, it is at least both children and can be placed (`ReadyToPlace`).
All required edges are now ordered, completing repair.

If the child is greater, move it into the hole and move the hole to its old
position. The promoted value dominates the saved value and the sibling, and
the additional parent condition preserves the edge above it. At the new hole,
all edges except its outgoing edges remain ordered. Its new parent holds the
promoted child's old value, which dominated that child's children because its
subtree was a heap. Thus the additional condition is preserved too.

In the logical live sequence this move exchanges the saved identity with one
child, so no identity is lost or duplicated. The eventual saved-value write
makes the physical array equal the logical sequence again. Repair touches only
the path from its root downward, leaving all other nodes and the extracted
suffix unchanged.

### Bottom-up construction

Leaves already satisfy heap order. Begin at `floor(n/2)` and work backward.
Before repairing index `build`, every parent index greater than it is ordered
(`BuiltSubtrees`), so its child subtrees are heaps. Repair establishes heap
order at this root and preserves all already-processed relationships. Decreasing
`build` continues the induction. At zero, every parent is ordered and the entire
prefix is a max-heap.

### Extraction and final positions

At each extraction boundary, `[1, size]` is a max-heap (`HeapAtBoundary`), and
every position after `size` is final (`SuffixFinal`). Exchange the root maximum
with the last heap position. It now occupies a final position: it dominates
all remaining prefix values, and the prior final suffix dominates it.

Shrink `size`. Removing the old last leaf preserves every remaining child
subtree, and only the new root can violate heap order. Repair restores the
heap while preserving identities and the final suffix. Repeating the argument
extends that suffix until at most one heap element remains. The whole array is
then sorted (`SortedAtEnd`). Empty/singleton inputs need no repairs or exchanges;
the model merely transitions from construction mode to sorting mode.

This establishes preservation, heap construction/repair, final extracted
positions, and sorted output for arbitrary finite integer arrays.

## Instability witness

Even with left-first child ties, exchanging the root with the last element can
reverse equal identities:

```text
input and built heap:  0₁  0₂
after extraction:     0₂  0₁
```

`Unstable.cfg` deliberately asserts `StableAtEnd` for `original = <<0, 0>>`.
Run `make heap-witness TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar`. The target
succeeds only when TLC reports the intended invariant violation, not a tool
error. The verified trace reaches identity order `<<2, 1>>` in 10 states.
Normal `HeapSort.cfg` makes no stability assertion and passes its checks.

## Correspondence and accesses

Subtract one from model node indices to obtain C++ indices; the model's heap
size is numerically the C++ exclusive bound `end`. `StartBuild` loads the saved
value for a construction repair. `Extract` combines the root/last swap, heap
shrink, and saved-value load for a sorting repair. `FindChildren` checks for a
left child; `SelectChild` compares siblings; `Compare`, `Move`, and `Place`
correspond to the saved-value test, upward assignment, and final placement.
The `root`, `mode`, and `phase` variables make call/loop control explicit.
Original-index identities are proof bookkeeping absent from C++.

An active repair has `1 <= root <= hole <= size`, and the saved identity is
valid. A child is accessed only when it exists, and a right child is read only
when its index is within the heap (`AccessSafety`). In C++, testing
`hole < end/2` before calculating `2*hole+1` guarantees both the multiplication
and child index are safe. The right-child candidate `child+1` is at most `end`;
short-circuit evaluation prevents a read at the exclusive bound. Construction
decrements only a positive root count, and extraction decrements only when
`end > 1`. Values are only copied and compared, including integer extrema.

## Termination and performance

Within repair, every move strictly increases the hole index to an existing
child and descends one tree level. Between moves there are finitely many
selection/comparison steps, after which the algorithm either moves or places
the saved value. The tree is finite, so each repair terminates. Construction
performs exactly `floor(n/2)` repairs, decreasing `build` after each. Sorting
performs at most `n-1` extractions, decreasing `size` before each repair. Thus
the entire sequence of nonstuttering steps is finite. Every nonterminal state
enables a step; weak fairness excludes endless stuttering and establishes the
model's `Terminates` property. C++ executes these finite loops directly.

A repair costs O(h) for subtree height h. In the array tree, at most
`floor(n/2^h)` nodes have height at least h. Summing the possible descents over
all construction roots gives at most `sum(h>=1, floor(n/2^h)) < n`, plus linear
constant work, establishing O(n) bottom-up construction.

Each extraction costs O(log n) in the worst case, giving O(n log n) worst-case
sorting time. One saved value and a fixed number of indices use O(1) auxiliary
space, with no allocation or recursion. Moving children through a hole uses
one assignment per descended level and one final placement rather than a full
swap at every level.

TLC checked all 1,093 inputs of lengths 0–6 over `{-1, 0, 1}`: 51,257 generated
states, 50,164 distinct states, depth 64, with no safety or termination errors.
The general argument above is separate from bounded checking; no machine-checked
C++ refinement or general TLAPS proof is claimed.
