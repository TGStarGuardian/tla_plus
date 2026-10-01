# Selection sort

`selection_sort.hpp` implements classic selection sort: scan the remaining
suffix for its first minimum and exchange it with the first suffix element,
skipping self-swaps. `SelectionSort.tla` separates starting a scan, each value
comparison/minimum update, scan completion, and exchange.

```cpp
#include "selection_sort/selection_sort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
selection_sort::sort(values);
```

Run `make test` and
`make selection-model TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar` from the
repository root. See [shared verification conventions](../common/README.md)
for identity semantics, complete results, and verification limitations.

## General correctness argument

Use one-based indices here. Before processing position `i`, every position in
`[1, i)` is already final: its value is at least every earlier value and at
most every later value (`PrefixFinal`). Initially this prefix is empty.

Initialize `minimum = i` and `cursor = i + 1`. Throughout the scan, `minimum`
is the first occurrence of a minimum value in `[i, cursor)` (`MinimumCorrect`).
The claim holds for the initial one-element interval. A strictly smaller
candidate becomes the new minimum; an equal or greater candidate leaves the
minimum unchanged. Advancing the cursor therefore preserves the invariant,
including the first-occurrence condition.

At scan completion, the minimum is at most every value in `[i, n]`. Exchanging
it with position `i` makes that position final: the earlier prefix was already
at most every suffix element, and the new value is at most every remaining
suffix value. Earlier final positions remain final because this operation only
permutes the suffix. Every swap preserves all identities and therefore all
value multiplicities (`PreservesElements`). Incrementing `i` extends the final
prefix. Once `i >= n`, all but possibly the last position are final, which
forces the whole array to be sorted. Empty/singleton inputs are immediately done.

## Why first-minimum selection is still unstable

Label elements by their original identities:

```text
input:              1₁  1₂  0₃
after first swap:   0₃  1₂  1₁
final:              0₃  1₂  1₁
```

Moving the original first element to the minimum's old position crosses an
equal element. Choosing the first minimum cannot prevent this.

`Unstable.cfg` checks the deliberately false `StableAtEnd` invariant for
`original = <<1, 1, 0>>`. Run:

```sh
make selection-witness TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
```

The target succeeds only when TLC finds the intended invariant violation. The
verified trace reaches identity order `<<3, 2, 1>>` in 10 states. Normal
`SelectionSort.cfg` does not assert stability and passes all of its properties.

## Accesses, termination, and performance

An active scan has `1 <= i < n`, `i <= minimum < cursor <= n + 1`. The candidate
is read only when `cursor <= n`; the exchange uses valid `i` and `minimum`.
The C++ empty-input guard precedes `size() - 1`, so unsigned subtraction is safe.
Indices only advance to their upper bounds, and values are only compared/copied.

For nonterminal states use `(max(0, n - i), V)` as a lexicographic rank: `V` is
`n + 3` in `ready`, `n - cursor + 2` in `scan`, and zero in `swap`. Starting,
comparing, and ending a scan strictly lower `V`; exchange increments `i` and
lowers the first component. Every nonterminal state enables a step. This proves
termination under the model's weak fairness assumption; the C++ loops execute
the same finite sequence directly.

There are exactly `n(n-1)/2` value comparisons and at most `max(0, n-1)` swaps.
Runtime is Θ(n²), including on already sorted input. Extra space is O(1), with
no allocation or recursion. This trades stability and adaptive runtime for a
small number of writes.

TLC checked 29,803 distinct states for normal safety and termination, separately
from the expected-failure stability witness. The argument above covers arbitrary
finite integer arrays.
