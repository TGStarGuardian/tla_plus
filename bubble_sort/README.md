# Bubble sort

`bubble_sort.hpp` implements stable bubble sort with a shrinking upper bound
and early exit after a pass with no swaps. `BubbleSort.tla` separates each
comparison, adjacent swap, scan advance, and pass completion.

```cpp
#include "bubble_sort/bubble_sort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
bubble_sort::sort(values);
```

From the repository root, run `make test` and
`make bubble-model TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar`. See
[shared verification conventions](../common/README.md) for original-index
identities, complete test results, and the limits of bounded checking.

## General correctness argument

Use one-based positions, as in TLA+. `bound` is the last position of the
unfinished prefix; every position after it is already final (`SuffixFinal`).
Initially the suffix is empty. At the start of a pass, `i = 1` and `swapped`
is false. Before comparing positions `i` and `i+1`, the value at `i` is a
maximum of `[1, i]`. This is trivially true for the singleton prefix.

If the left value exceeds the right, swap them. Otherwise leave them in place.
The value at `i+1` is now a maximum of `[1, i+1]`. Advancing the scan reestablishes
the induction hypothesis. `ScanMaximum` checks the appropriate prefix maximum
both before comparison and after comparison/swap.

At pass completion, the value at `bound` is at least every earlier value. The
existing final suffix is at least every value of the unfinished prefix, so this
new position is also final (`PassFinal`). Decreasing `bound` therefore extends
the final sorted suffix. Later swaps stay within the shorter unfinished prefix
and preserve every established final position.

If no swaps occurred, the array was unchanged throughout the pass. Every
adjacent pair of the unfinished prefix was compared and found ordered. The
prefix is therefore sorted, and its relationship to the existing final suffix
makes the entire array sorted (`NoSwapsSorted`). Early exit is sound. If the
upper bound instead reaches zero or one, the final suffix already forces the
whole array to be sorted. This also handles empty and singleton inputs.

Every data mutation is a swap, preserving each original identity and therefore
value multiplicities (`PreservesElements`). Swaps only exchange strictly
inverted adjacent values. Equal-valued identities can change relative order
only by crossing each other, which never happens, proving `StableOrder` and
the stable final result.

## Accesses, termination, and performance

In an active comparison or swap, `1 <= i < bound <= n`, so both positions are
valid (`AccessSafety`). The C++ inner index points to the right element of that
pair: it compares `a[i-1]` with `a[i]` for `1 <= i < end`. TLA+ position `k`
maps to C++ position `k-1`. C++ `end` equals the model's `bound` numerically.
The outer loop decrements only while `end > 1`, and the inner loop increments
only to `end`; there is no unsigned underflow or overflowing array-value
arithmetic.

Each comparison reaches an advance after at most one swap. Each advance
increases `i`, so a pass finishes after `bound-1` comparisons. A completed pass
either terminates immediately or strictly decreases `bound`. Hence the number
of nonstuttering steps is finite. Every nonterminal state enables a step;
weak fairness of `Next` excludes infinite stuttering and proves `Terminates`.
C++ performs the same finite work directly.

The first pass on sorted or all-equal input costs O(n) and exits. In the worst
case, passes perform `(n-1)+(n-2)+...+1` comparisons and O(n²) swaps, giving
O(n²) time. Indices, a swap temporary, and the flag use O(1) auxiliary space;
there is no allocation or recursion.

TLC checked all 1,093 inputs of lengths 0–6 over `{-1, 0, 1}`: 37,016 generated
states, 35,923 distinct states, depth 53, and no invariant or termination errors.
This bounded check complements the general argument above; neither is a
machine-checked proof of the C++ implementation.
