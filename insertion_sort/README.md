# Insertion sort

`insertion_sort.hpp` implements ordinary stable insertion sort using one saved
key and rightward shifts. `InsertionSort.tla` models loading the key, each
comparison, each shift, and final placement as separate actions.

```cpp
#include "insertion_sort/insertion_sort.hpp"
#include <vector>

std::vector<int> values{3, -1, 3, 0};
insertion_sort::sort(values);
```

Run `make test` and
`make insertion-model TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar` from the
repository root. See [shared verification conventions](../common/README.md)
for identity semantics, complete test results, and verification limitations.

## General correctness argument

Use one-based indices here, matching TLA+; C++ indices are smaller by one.
At each outer-loop boundary `i`, the prefix `[1, i)` is a stable sorted
permutation of the original prefix, and the suffix `[i, n]` is unchanged.
This is `PrefixCorrect`. It initially holds for a singleton prefix; the empty
array is already done. These prefix positions are not necessarily final sorted
positions: later insertions can move them.

Load identity `key = a[i]` and let `j = i`. Regard position `j` as a hole, even
though its old physical value remains in the array. Define `Live` by replacing
that position with the saved key. Thus every original identity occurs exactly
once in `Live` (`PreservesElements`).

Removing the hole from `[1, i]` gives the prior stable sorted prefix. Maintain
that this sequence remains sorted and every element in `(j, i]` is strictly
greater than the key (`ShiftInvariant`). If `j > 1` and the predecessor is
greater than the key, copying it to the hole and decrementing `j` shifts one
element right. It leaves the hole-removed sequence unchanged. In `Live`, this
is exactly an exchange of the key with that greater predecessor: identities
are preserved, and equal identities never cross. The suffix after `i` is
untouched. Consequently `StableOrder` is preserved globally.

On exit from the comparison loop, either `j = 1` or the predecessor is at most
the key. Every successor through `i` is greater, so placing the saved key fills
the hole and makes `[1, i]` a stable sorted permutation of the original prefix
of length `i`. Incrementing `i` reestablishes `PrefixCorrect`. At termination,
the prefix covers the array, proving stable sorted output and multiplicities.
The strict `>` test is essential: shifting on equality would destroy stability.

## Accesses, termination, and performance

`Load` requires `i <= n`; while active, `1 <= j <= i <= n`. The predecessor is
read only when `j > 1`, and the key is placed at `j`, a valid index. C++ uses
the corresponding short-circuit `j > 0` guard before subtracting one.
Array values are never added or subtracted, so integer extrema are safe.

A formal decreasing measure for nonterminal model steps is the lexicographic
pair `(n + 1 - i, V)`, where `V` is `2n + 3` in `ready`, `2j` in `compare`,
`2j - 1` in `shift`, and zero in `place`. Loading lowers `V`; comparison chooses
a lower phase rank; shifting reduces `j`; placement increments `i`. Every
nonterminal state enables a step. This well-founded descent, together with
weak fairness excluding endless stuttering, proves `Terminates` for all finite
inputs. The direct C++ loops make the same progress without a fairness premise.

Each shift removes one strict inversion. If the input has `I` inversions,
runtime is O(n + I): O(n) on sorted/all-equal inputs and O(n²) in the worst
case. One saved key and indices require O(1) auxiliary space; there is no
allocation or recursion.

TLC checked 25,156 distinct states for the configured domain, including the
live-data invariant, stable prefix, access bounds, stable final result, and
termination. This bounded result complements the general argument above.
