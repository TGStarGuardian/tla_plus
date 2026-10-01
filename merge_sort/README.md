# Merge sort

`merge_sort.hpp` implements stable bottom-up merge sort. It allocates one
reusable buffer, merges adjacent runs of width 1, 2, 4, and so on, and copies
each completed merged chunk back into the array. `MergeSort.tla` exposes each
head comparison, buffer write, and copy-back write.

```cpp
#include "merge_sort/merge_sort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
merge_sort::sort(values);
```

Run `make test` and
`make merge-model TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar` from the
repository root. See [shared verification conventions](../common/README.md)
for identity semantics, complete results, and verification limitations.

## General correctness argument

Use one-based half-open intervals here; subtract one for C++ boundaries. Before
each pass, the array is a concatenation of stable sorted runs of at most
`width` elements. This is initially true for singleton runs, with empty and
singleton arrays immediately done.

Within a pass, everything before `lo` consists of completed stable sorted runs
of width at most `2*width`; everything from `lo` onward still consists of runs
of width at most `width`. `RunInvariant` states this on the logical live array.
The next two runs are `[lo, mid)` and `[mid, hi)`, truncated at `n + 1`.
The second run may be empty. `source` is a proof-only snapshot taken at the
beginning of each merge, and both source runs are stable sorted (`MergeShape`).

### Merge prefix

Initially set `left = lo`, `right = mid`, and `out = lo`. Maintain:

- `out - lo = (left - lo) + (right - mid)`;
- the buffer prefix `[lo, out)` contains exactly the identities consumed from
  the two source runs, in stable sorted order;
- every emitted identity precedes every unconsumed identity in the total order
  of value followed by original index.

These are `MergeShape` and `MergePrefix`; the empty prefix satisfies them.
If one run is exhausted, choose the head of the other. Otherwise choose the
smaller head, taking the left head on equality. Each head precedes everything
else in its own run. For equal-valued heads from opposite runs, the left one
has the earlier original identity: global `StableOrder` holds before merging.
Thus the chosen head is the least remaining identity in the stable total order.

Writing it to the buffer and advancing the corresponding cursor preserves the
prefix invariant. Exactly one identity is consumed each time. When `out = hi`,
the buffer chunk is therefore the complete stable sorted permutation of the
two source runs. This proves the requested intermediate merge-prefix property,
not just sortedness after a whole pass.

### Copy-back and completed passes

During buffer construction the source array stays unchanged. Stale or unused
buffer entries are not live elements. During copy-back, the completed buffer
chunk is authoritative, while the array outside `[lo, hi)` remains live.
`PreservesElements` therefore holds even when a partial physical copy creates
duplicates in `a`. `ArrayFrame` checks that the copied array prefix matches the
buffer and every other position still matches the source snapshot.

After the last copy, the array agrees with the logical live sequence again.
Its identities are unchanged in multiplicity, and equal identities remain in
original order: the stable merge preserves their order inside the chunk and
never crosses elements outside it. Advancing `lo` restores `RunInvariant` with
one more completed run. At the end of a pass, every run has width at most
`2*width`. Doubling the width restores the pass-entry claim; if the new width
would reach or exceed `n`, the array is a single stable sorted run and is done.
Thus `SortedAtEnd` and stability follow for any finite input.

## Correspondence and accesses

`BeginMerge` computes the boundaries and initializes cursors. `Compare` records
the selected source index, and `Write` performs the assignment and cursor
increments from one C++ loop iteration. `BeginCopy` starts copy-back; `Copy`
models one array write. `NextPass` models width growth. The model clamps the
final width to `n` and enters `Done`; C++ breaks out of the loop at that point.

The proof-only `source` snapshot is absent from C++. The modeled buffer starts
with arbitrary valid identities (here, input order), whereas C++ initializes
its integer buffer to zeros. Initial/stale buffer contents are irrelevant:
every entry read during copy-back was written by the current merge.

While producing output, `lo <= left <= mid <= right <= hi <= n + 1`. If output
remains, at least one run is nonempty. Short-circuit guards ensure only live
heads are read, and the write goes to `out < hi`. Copy-back accesses are within
`[lo, hi)`. These bounds and `AccessSafety` cover every modeled array access.

C++ computes boundaries by adding at most the remaining length, avoiding an
overflow-prone `lo + 2*width`. Width doubles only if `width < n - width`, so the
product remains below `n`. All other cursor increments stop at valid exclusive
bounds. Values are compared/copied without arithmetic, including integer extrema.

## Termination and performance

One explicit natural-number lexicographic rank for nonterminal model steps is
`(max(0, n-width), n+1-lo, V)`, with

```text
V = 3n + 3                          in ready
V = 2(hi-out) + (hi-lo) + 2          in compare
V = 2(hi-out) + (hi-lo) + 1          in write
V = hi-copy                         in copy
```

Starting a merge lowers `V`. Comparisons and buffer writes lower it in turn,
as does starting copy-back. Each copy lowers `V` until its last write advances
`lo`, reducing the second component. Completing a pass increases `width`,
reducing the first component. Every nonterminal state enables a step. Thus
well-founded descent and weak fairness establish `Terminates`. The C++ loops
execute this finite work directly.

Each pass writes every element once into the buffer and once back to the array,
with O(n) comparisons and boundary work. There are `ceil(log2(n))` passes for
`n >= 2`, giving Θ(n log n) time even for sorted inputs. The single buffer uses
O(n) extra space; indices use O(1), and there is no recursion or per-merge
allocation.

TLC checked 69,349 distinct states, including merge prefixes, run boundaries,
live identities, stable output, access safety, and termination. The general
argument is independent of the configured finite bound.
