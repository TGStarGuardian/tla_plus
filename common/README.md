# Shared verification conventions

`SortProperties.tla` contains sequence swaps, multiplicities, sortedness, final
positions, and properties for original-index identities. Algorithm transitions
stay in their own modules. Quicksort uses plain values; the other five models
use identities to make stability observable.

## Identities and live data

`original` is an immutable sequence of input values. Identity `k` means the
element originally at position `k`, and its value is `original[k]`. Initially
`a = <<1, 2, ..., n>>`. `Keys(a, original)` projects identities back to the
integer array manipulated by C++. `Stable` requires equal-valued elements to
occur in increasing original-index order. `Before` orders identities by value,
then original index; it is used to characterize a correct stable merge prefix.

`Permutation(Live, Identity(n))` proves every identity occurs exactly once in
the logical live data. This implies preservation of value multiplicities,
including duplicates. During insertion shifts and heap repair, `Live` fills
the temporary hole with the saved key/value. During merge copy-back, it uses the completed buffer chunk
instead of the partially overwritten array. At completed-operation boundaries,
`Live = a`, so the array itself is a permutation again.

These identities, input snapshots, and `Live` expressions are proof bookkeeping;
they add no C++ storage. The C++ APIs remain `void sort(std::span<int>)`, except
quicksort, which also accepts its random generator. Erasing identities and
replacing them by their values explains the correspondence. This is not a
machine-checked refinement proof of C++. In particular, integer-only C++ tests
cannot observe relative identities of equal values; stability is checked in
the models and justified by the corresponding comparison/write logic.

## Scope and progress

Each normal configuration checks all 1,093 input arrays of lengths 0–6 over
`{-1, 0, 1}`, including empty, singleton, negative, and duplicate cases. Quicksort
also explores every pivot choice. All configurations check termination as well
as the listed invariants. `MaxLen` and `ModelElements` control the finite input
domain; the latter is an operator override because negative numbers cannot be
written directly as TLC configuration literals.

TLA+ allows stuttering, so each `Spec` includes weak fairness of `Next` to require
eventual execution when work remains. No algorithm relies on a particular
scheduler or, for quicksort correctness, a particular pivot distribution.
Completed states can stutter forever and satisfy `<>Done`.

TLC results establish bounded model checking, with the usual state-fingerprint
collision qualification. The mathematical proofs in the algorithm READMEs
apply to arbitrary finite integer arrays. No machine-checked general/TLAPS
proof, probabilistic model-checking result, or C++ compiler proof is claimed.
C++ integer values are bounded by `int`; TLA+ integers are unbounded. Values are
only copied and compared, while safe index arithmetic is explained per algorithm.

## Reproduce

From the repository root, using C++20, GNU Make, Bash, Java, and a TLA+ tools JAR:

```sh
make test
make models TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
make selection-witness heap-witness TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
# Or run all checks:
make check TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
```

Individual model targets are `quicksort-model`, `insertion-model`,
`selection-model`, `merge-model`, `bubble-model`, and `heap-model`. The Makefile sets `TLA-Library` to the
shared module directory. For a direct Java invocation or IDE configuration,
include `-DTLA-Library=/absolute/path/to/this/repo/common` among JVM options.

Binaries and TLC logs go to `/tmp/tla-plus-checks` by default. To change this,
set `BUILD_DIR` to another absolute path. Tests keep assertions enabled and
use AddressSanitizer and UndefinedBehaviorSanitizer. Header consumers can build
with `-O3` without the test instrumentation.

`selection-witness` and `heap-witness` deliberately ask TLC to check false
stability invariants.
The Make target succeeds only if TLC exits with invariant-violation code 12 and
reports `StableAtEnd`; a tool/setup error will fail the target. The trace is
saved as `selection-witness.log` or `heap-witness.log`. This is separate from normal safety checks.

## Validation record

Checked on 2026-10-01 using GCC 13.3.0, Java 21, and TLC 2026.10.01.024053:

| Model | Generated states | Distinct states | Search depth | Result |
| --- | ---: | ---: | ---: | --- |
| Quicksort (shared-module regression) | 64,835 | 49,719 | 22 | All checks passed |
| Insertion sort | 26,249 | 25,156 | 40 | All checks passed, including stability |
| Selection sort | 30,896 | 29,803 | 31 | All normal checks passed |
| Merge sort | 70,442 | 69,349 | 70 | All checks passed, including stability |
| Bubble sort | 37,016 | 35,923 | 53 | All checks passed, including stability |
| Heap sort | 51,257 | 50,164 | 64 | All normal checks passed |
| Heap instability witness | 10 | 10 | 10 | Expected `StableAtEnd` violation |
| Selection instability witness | 10 | 10 | 10 | Expected `StableAtEnd` violation |

The respective optimistic fingerprint collision estimates for the six normal
runs were `4.1e-11`, `1.5e-12`, `1.8e-12`, `4.1e-12`, `2.1e-12`, and `3.0e-12`.

C++ checks passed for all six implementations without sanitizer errors. Each
deterministic algorithm sorted all 9,841 arrays of lengths 0–8 over `{-1, 0, 1}`, both as
whole arrays and as subspans surrounded by untouched sentinels. Additional
checks cover integer limits, equal/sorted/reversed/random arrays through 2,048
elements, and merge/heap-sort sizes 65,535, 65,536, 65,537, and 100,000. Quicksort's
existing exhaustive, partition, and large-input checks also passed.
