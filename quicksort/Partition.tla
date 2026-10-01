---------------------------- MODULE Partition ----------------------------
EXTENDS SortProperties

PartitionInvariant(a, lo, hi, lt, scan, gt, pivot) ==
    /\ 1 <= lo /\ lo <= lt /\ lt <= scan /\ scan <= gt
    /\ gt <= hi /\ hi <= Len(a) + 1
    /\ \A k \in Indices(lo, lt) : a[k] < pivot
    /\ \A k \in Indices(lt, scan) : a[k] = pivot
    /\ \A k \in Indices(gt, hi) : a[k] > pivot
    /\ \E k \in Indices(lo, hi) : a[k] = pivot

\* Precondition: PartitionInvariant and scan < gt.
PartitionStep(a, lt, scan, gt, pivot) ==
    IF a[scan] < pivot THEN
        [array |-> Swap(a, lt, scan), lower |-> lt + 1,
         cursor |-> scan + 1, upper |-> gt]
    ELSE IF a[scan] > pivot THEN
        [array |-> Swap(a, scan, gt - 1), lower |-> lt,
         cursor |-> scan, upper |-> gt - 1]
    ELSE
        [array |-> a, lower |-> lt, cursor |-> scan + 1, upper |-> gt]
=============================================================================
