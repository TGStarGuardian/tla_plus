Ovo je biblioteka za proveru algoritama u jeziku TLA+, za potrebe kursa Formalne metode, na doktorskim studijama na Matfu.

## Quicksort

[Implementation, TLA+ verification, proofs, and run commands](quicksort/README.md).

Project conventions and the agreed verification scope are recorded in [AGENTS.md](AGENTS.md).

## Other sorting algorithms

| Algorithm | Implementation and proof | Time | Auxiliary space | Stable |
| --- | --- | --- | --- | --- |
| Insertion sort | [Documentation](insertion_sort/README.md) | O(n) best, O(n²) worst | O(1) | Yes |
| Selection sort | [Documentation](selection_sort/README.md) | Θ(n²) | O(1) | No |
| Merge sort | [Documentation](merge_sort/README.md) | Θ(n log n) | O(n) | Yes |
| Bubble sort | [Documentation](bubble_sort/README.md) | O(n) best, O(n²) worst | O(1) | Yes |
| Heap sort | [Documentation](heap_sort/README.md) | O(n log n) worst | O(1) | No |

Each directory contains an integer-only C++ implementation, a TLA+ model, and
its TLC configuration. Shared sequence definitions live in
[common/SortProperties.tla](common/SortProperties.tla).

## Run verification

```sh
make check TLA_TOOLS_JAR=/absolute/path/to/tla2tools.jar
```

This runs C++ checks with sanitizers, all six TLC models, and the expected
selection-sort and heap-sort stability counterexamples. Each normal model checks every input
of length 0–6 over `{-1, 0, 1}`, including termination. See
[verification conventions and results](common/README.md) for individual commands,
identity-based stability checks, and the distinction between bounded checking,
general mathematical arguments, and C++ correspondence.
