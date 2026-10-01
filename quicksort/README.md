# Quicksort

An in-place C++20 quicksort and a TLA+ model of the same three-way partition
algorithm. The equal-to-pivot block reaches its final sorted positions **after
a complete partition**, not after a single comparison or swap.

## Files and use

- `quicksort.hpp`: integer sorting API and partition implementation.
- `Partition.tla`: partition invariant and steps; shared sequence properties
  live in `../common/SortProperties.tla`.
- `Quicksort.tla`: pivot choice, partition execution, and remaining work.
- `Quicksort.cfg`: bounded safety and termination checks.
- `test.cpp`: executable checks against `std::sort` and partition contracts.

```cpp
#include "quicksort/quicksort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
std::mt19937 random(42);  // Explicit seed for reproducibility.
quicksort::sort(values, random);
```

The API accepts `std::span<int>`, including an empty span. It mutates the supplied
storage and uses a caller-owned generator. `detail::partition` requires a valid
nonempty range and a pivot index inside it. The public sorter establishes these
preconditions. This is an unstable sort: equal elements have no identity/order
guarantee.

## Run checks

From the repository root, with GCC (or Clang), Java, and a TLA+ tools JAR:

```sh
g++ -std=c++20 -O1 -g -Wall -Wextra -Wpedantic -Wconversion \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    quicksort/test.cpp -o /tmp/tla-quicksort-test
/tmp/tla-quicksort-test

export TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
cd quicksort
java -DTLA-Library=../common -XX:+UseParallelGC -Xmx2g -cp "$TLA_TOOLS_JAR" tlc2.TLC \
    -workers 2 -metadir /tmp/tla-quicksort-states \
    -config Quicksort.cfg Quicksort.tla
```

Keep assertions enabled in the test build. For an optimized consumer build, use
`-O3`; the sorter itself does not depend on assertions or sanitizers. The JAR
bundled with the installed VS Code TLA+ extension also works.

`MaxLen` controls exhaustive input length. `Elements` is overridden by the
`ModelElements` operator because TLC configuration literals do not accept
negative integers directly. Adjust that operator to change the finite domain.

Checked on 2026-10-01 with GCC 13.3.0, Java 21, and TLC 2026.10.01.024053:

- C++: 9,841 inputs of lengths 0–8 over `{-1, 0, 1}`, each sorted with three
  seeds; every nonempty subrange and pivot index for lengths 0–6; integer limits;
  and 100,000-element equal, ascending, descending, and pseudorandom inputs.
  AddressSanitizer and UndefinedBehaviorSanitizer reported no errors.
- TLC: all 1,093 inputs of lengths 0–6 over `{-1, 0, 1}` and all possible pivot
  values at every partition. It generated 64,835 states, found 49,719 distinct
  states, and completed every configured invariant and termination check with
  no errors. Search depth was 22. TLC uses state fingerprints; its reported
  optimistic collision estimate for this run was approximately `4.1e-11`.

## Model and correspondence

Both implementations use half-open intervals `[lo, hi)`. C++ indices are
zero-based; TLA+ sequence indices are one-based. Add one to every C++ boundary
or cursor to obtain its TLA+ counterpart. Values are unchanged.

| C++ operation | TLA+ operation |
| --- | --- |
| Uniform pivot index, then copy its value | `Start` nondeterministically chooses an index and copies `a[p]` |
| One partition-loop iteration | `Scan`, using `PartitionStep` |
| Return `[lt, gt)` | Reach phase `"split"` |
| Recurse into smaller side, then iterate over larger | `Finish` prepends the smaller task, then the larger task, to `pending` |
| Return immediately for length 0 or 1 | Omit empty tasks and mark singleton indices fixed |

Equal-valued pivot indices yield identical model states; merging them loses no
array behavior. A pivot is a copied **value**, not a tracked element identity.
The model does not represent the generator or its probabilities.

`pending` represents continuations of suspended C++ calls and the next range to
sort. It omits trivial calls and function returns. `original` and `fixed` are
proof bookkeeping, absent from C++. The model's explicit sequence, copies, and
unbounded integers describe behavior rather than implementation memory costs.
This is an explained correspondence, not a machine-checked C++ refinement proof.

## General correctness argument

The following induction and termination arguments apply to any finite sequence
of integers, independently of the configured TLC bound. They are mathematical
proofs in prose; no TLAPS proof is claimed.

### Partition invariant and accesses

During partitioning, maintain

```text
lo <= lt <= scan <= gt <= hi
[lo, lt)    < pivot
[lt, scan)  = pivot
[scan, gt)  unclassified
[gt, hi)    > pivot
```

The active interval contains at least one occurrence of the pivot. Initially
`lt = scan = lo`, `gt = hi`, and the pivot was copied from inside the interval.
All three classified regions are empty, so the invariant holds.

When `scan < gt`, `lt`, `scan`, and `gt - 1` are valid indices in the active
interval. Consider the three branches:

1. If `a[scan] < pivot`, swap it with `a[lt]` and increment both cursors. When
   `lt < scan`, the displaced value equals the pivot; when `lt = scan`, the swap
   is a self-swap. In both cases the smaller region grows by one and the equal
   region remains correct.
2. If `a[scan] > pivot`, decrement `gt` and swap with that index. The greater
   region grows by one. Keep `scan` unchanged because the incoming value has
   not yet been classified, unless the unknown region has just become empty.
3. Otherwise increment `scan`, extending the equal region.

Each step decreases `gt - scan` by exactly one. Swaps preserve multiplicities
and leave everything outside the interval unchanged, so a pivot occurrence
remains. Thus a partition of length `m` takes exactly `m` loop iterations.

At exit `scan = gt`. The unknown region is empty, and the existing pivot
occurrence must lie in `[lt, gt)`, so `lt < gt`. The interval is now partitioned
into strictly smaller, equal, and strictly greater blocks.

### Final pivot positions and the complete sort

Maintain these outer invariants (expressed as `WorkCoverage`, `Separated`, and
`FixedFinal`): unfinished intervals and fixed indices disjointly cover the
array; every value before an unfinished interval is at most every value inside
it, and every value inside is at most every value after it; every fixed index
is ordered relative to all earlier and later indices.

Initially there is either one whole-array task, for which separation is
vacuous, or an empty/singleton array whose indices are already fixed. A partition
only permutes values inside one unfinished interval, preserving its separation
from the outside and all previous fixed positions.

On partition completion, an equal-block value is at least every earlier value
and at most every later value: the partition invariant handles the active
interval and separation handles everything outside it. This is `PivotFinal`.
Consequently these are final sorted positions. With duplicates, this statement
concerns values and indices rather than a unique identity for each occurrence.

Replacing the parent interval with its two strict children preserves separation
and disjoint coverage. Its nonempty equal block becomes fixed; singleton
children are also already final, and empty children contribute no work. All
future swaps stay inside unfinished intervals, so fixed values never move.

Every transition either swaps values or leaves the array unchanged, proving
`PreservesValues`. Once no unfinished work remains, coverage makes every index
fixed, proving `SortedAtEnd`. Therefore the result is a sorted permutation of
the input. Empty arrays and singleton arrays satisfy this immediately.

### Termination

Let `n` be the original length and `U` the sum of lengths of all unfinished
intervals, including an active partition. Define a secondary natural measure:

```text
V = n + 2          in phase idle
V = gt - scan + 1  in phase scan
V = 0              in phase split
```

Every nonterminal transition strictly decreases the lexicographic pair `(U,V)`:
`Start` preserves `U` and lowers `V`; `Scan` preserves `U` and lowers `V`;
`Finish` strictly lowers `U` by removing a nonempty equal block (and any
singleton children). This order on pairs of natural numbers is well-founded.
Each nonterminal reachable state enables a transition. TLA+ allows stuttering,
so `WF_vars(Next)` requires eventual progress whenever work remains; hence
`Terminates`, or `<>Done`. The fairness condition concerns scheduling only:
correctness and termination require no fair distribution of pivot choices.

C++ executes these steps directly. Its unsigned subtractions cannot underflow
under the interval invariant. Cursor increments stop at the exclusive upper
bound, and array values are only compared or copied, including `INT_MIN` and
`INT_MAX`.

## Performance argument

A partition costs O(m) time and O(1) extra storage. With distinct values and
repeated extreme pivots, remaining sizes can be `m-1, m-2, ...`, giving O(n²)
worst-case time. An all-equal input takes one linear partition.

For expected time, assume each pivot index is chosen uniformly conditional on
the current interval, as in the usual idealized randomized quicksort analysis.
Fix an arbitrary ordering among equal values for analysis. A middle-half rank
is chosen with probability at least one half, up to harmless rounding for small
intervals. Such a pivot leaves both strict children of size at most about
three quarters of the parent; grouping equal values can only shrink them.
For any particular element, the expected wait for each such shrink is constant,
and O(log n) shrinks suffice until it becomes fixed. Charging each partition's
linear cost to its elements therefore gives O(n log n) expected total time.
The C++ implementation uses `uniform_int_distribution` with `mt19937`; a fixed
seed determines a particular execution, and the idealized expectation is not
a worst-case guarantee for that seed. TLC establishes no probabilistic bound.

The recursive child has size at most `floor((m-1)/2)` because the equal block is
nonempty. Each deeper C++ call thus at least halves the size; the larger side
runs in the current frame. Stack space is O(log(n+1)) for **every** pivot
sequence, with O(1) extra storage per frame and no auxiliary array allocation.
