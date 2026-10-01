# Project rules

Keep implementations minimal, simple, and modular. TLA+ is the primary language
for specifying and verifying algorithms; C++ provides executable references.

# Agreed quicksort design

- Sort finite integer arrays, including empty arrays, negative values, and duplicates.
- Use in-place randomized three-way partitioning. Recurse into the smaller
  partition and iterate over the larger one: expected O(n log n) time,
  O(n squared) worst-case time, and O(log n) stack space.
- Separate partition definitions from the complete sorting model. Model each
  partition-loop iteration, including swaps and index updates. Model pivot
  choice nondeterministically; assume uniform random choice only in the
  expected-runtime argument.
- Establish that after a complete partition the equal-to-pivot block occupies
  final sorted positions. Also establish preservation of multiplicities,
  valid accesses, termination, and sorted output.
- Check all arrays of length 0–6 over {-1, 0, 1} with TLC, including all modeled
  pivot choices. Supply a general mathematical argument for arbitrary finite
  integer arrays and separate performance arguments.
- Clearly distinguish bounded model checking, mathematical proof, and the
  explained correspondence to C++. A machine-checked general proof and a
  machine-checked proof of the C++ program are outside the agreed scope.
- Include meaningful C++ correctness checks and reproducible run commands.

When changing quicksort, read `quicksort/README.md` for the proof and model/C++
correspondence, then run the C++ checks and TLC configuration documented there.

# Agreed insertion, selection, and merge sort design

- Use ordinary stable shift-based insertion sort: O(n) best time, O(n squared)
  worst time, O(1) auxiliary space. Each completed insertion leaves a sorted
  prefix containing exactly the original prefix's elements.
- Use classic selection sort, choosing the first minimum and skipping self-swaps:
  O(n squared) comparisons, O(n) swaps, O(1) space. Each completed selection
  fixes another final sorted position. Demonstrate its instability.
- Use stable bottom-up merge sort with one reusable O(n) buffer and O(n log n)
  time. Establish correct merge prefixes and sorted runs after each pass.
- Model comparisons and data writes explicitly. Track saved insertion keys and
  live merge-buffer contents when the array alone is not a permutation.
- Keep C++ APIs integer-only. Use original-index identities in TLA+ to verify
  insertion/merge stability; explain correspondence without claiming a
  machine-checked C++ proof.
- For all three, establish multiplicities, valid accesses, termination, and
  sorted output. Exhaust lengths 0–6 over {-1, 0, 1} with TLC, supplement with
  exhaustive/larger C++ checks and general mathematical/performance arguments.
- Keep separate algorithm directories and shared sequence properties in
  common/SortProperties.tla. Preserve quicksort behavior when extracting helpers.

When changing a sorter, read its directory's README.md for its invariants and
proof. Run `make test` and the affected model target; when changing shared TLA+
definitions, run `make models TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar`.
`make selection-witness` is an expected-failure check of selection instability.

# Agreed bubble and heap sort design

- Use stable bubble sort with strict adjacent swaps, a shrinking upper bound,
  and early exit after a no-swap pass: O(n) best time, O(n squared) worst time,
  O(1) space. Check the scanned-prefix maximum, final sorted suffix, and that
  a no-swap pass implies sorted output.
- Use bottom-up max-heap construction and iterative saved-value/hole repair:
  O(n) construction, O(n log n) worst-case sorting, O(1) space. Choose the left
  child on equality and stop when the saved value is at least the larger child.
- Check processed heap subtrees, repair invariants around the hole, and the
  remaining heap and final suffix after extraction. Track logical live elements
  during repair. Demonstrate heap sort's instability with a separate TLC witness.
- Follow the existing integer-only C++ APIs, proof-only identities, shared TLA+
  definitions, finite-domain checks, and general mathematical proofs. Exhaust
  lengths 0–6 over {-1, 0, 1} and run all existing checks as regressions.
- Run `make heap-witness` for the expected heap-stability counterexample, supplying
  TLA_TOOLS_JAR as for the other model targets.
