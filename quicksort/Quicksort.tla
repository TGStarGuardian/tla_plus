---------------------------- MODULE Quicksort ----------------------------
EXTENDS Partition, TLC

CONSTANTS MaxLen, Elements
ASSUME /\ MaxLen \in Nat /\ Elements \subseteq Int
       /\ IsFiniteSet(Elements)

VARIABLES original, a, pending, fixed, phase, lo, hi, lt, scan, gt, pivot
vars == <<original, a, pending, fixed, phase, lo, hi, lt, scan, gt, pivot>>

Inputs == UNION {[1..n -> Elements] : n \in 0..MaxLen}
ModelElements == {-1, 0, 1}
Range(r) == Indices(r[1], r[2])
Size(r) == r[2] - r[1]
Task(r) == IF Size(r) > 1 THEN <<r>> ELSE <<>>
Singleton(r) == IF Size(r) = 1 THEN Range(r) ELSE {}
Active == IF phase = "idle" THEN <<>> ELSE << <<lo, hi>> >>
Work == Active \o pending

Init ==
    /\ original \in Inputs
    /\ a = original
    /\ pending = Task(<<1, Len(a) + 1>>)
    /\ fixed = IF Len(a) <= 1 THEN DOMAIN a ELSE {}
    /\ phase = "idle"
    /\ lo = 1 /\ hi = 1 /\ lt = 1 /\ scan = 1 /\ gt = 1 /\ pivot = 0

Start ==
    /\ phase = "idle" /\ pending # <<>>
    /\ LET r == Head(pending) IN
        /\ lo' = r[1] /\ hi' = r[2]
        /\ lt' = r[1] /\ scan' = r[1] /\ gt' = r[2]
        /\ \E p \in Range(r) : pivot' = a[p]
    /\ pending' = Tail(pending)
    /\ phase' = "scan"
    /\ UNCHANGED <<original, a, fixed>>

Scan ==
    /\ phase = "scan" /\ scan < gt
    /\ LET s == PartitionStep(a, lt, scan, gt, pivot) IN
        /\ a' = s.array /\ lt' = s.lower
        /\ scan' = s.cursor /\ gt' = s.upper
        /\ phase' = IF s.cursor = s.upper THEN "split" ELSE "scan"
    /\ UNCHANGED <<original, pending, fixed, lo, hi, pivot>>

Finish ==
    /\ phase = "split"
    /\ LET left == <<lo, lt>>
           right == <<gt, hi>>
           children == IF Size(left) < Size(right)
                       THEN Task(left) \o Task(right)
                       ELSE Task(right) \o Task(left)
       IN /\ pending' = children \o pending
          /\ fixed' = fixed \cup Indices(lt, gt)
                      \cup Singleton(left) \cup Singleton(right)
    /\ phase' = "idle"
    /\ UNCHANGED <<original, a, lo, hi, lt, scan, gt, pivot>>

Done == phase = "idle" /\ pending = <<>>
Next == Start \/ Scan \/ Finish \/ (Done /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

TypeOK ==
    /\ original \in Inputs /\ a \in [1..Len(original) -> Elements]
    /\ pending \in Seq((1..(Len(a) + 1)) \X (1..(Len(a) + 1)))
    /\ fixed \subseteq DOMAIN a
    /\ phase \in {"idle", "scan", "split"}
    /\ lo \in Nat /\ hi \in Nat /\ lt \in Nat
    /\ scan \in Nat /\ gt \in Nat /\ pivot \in Int

PreservesValues == Permutation(a, original)

\* Every unfinished interval is already ordered relative to its surroundings.
Separated ==
    \A t \in DOMAIN Work :
        LET r == Work[t] IN
            /\ \A i \in 1..(r[1] - 1), j \in Range(r) : a[i] <= a[j]
            /\ \A i \in Range(r), j \in r[2]..Len(a) : a[i] <= a[j]

WorkCoverage ==
    /\ \A t \in DOMAIN Work :
        /\ 1 <= Work[t][1] /\ Work[t][2] <= Len(a) + 1
        /\ Size(Work[t]) > 1
        /\ Range(Work[t]) \cap fixed = {}
    /\ \A s, t \in DOMAIN Work :
        s # t => Range(Work[s]) \cap Range(Work[t]) = {}
    /\ fixed \cup UNION {Range(Work[t]) : t \in DOMAIN Work} = DOMAIN a

PartitionCorrect == phase # "idle" =>
    PartitionInvariant(a, lo, hi, lt, scan, gt, pivot)

AccessSafety ==
    /\ phase = "scan" =>
        /\ scan < gt
        /\ {lt, scan, gt - 1} \subseteq DOMAIN a
    /\ phase = "split" => scan = gt

\* The main requested property, before Finish marks the equal block fixed.
PivotFinal == phase = "split" =>
    /\ lt < gt
    /\ \A k \in Indices(lt, gt) : a[k] = pivot /\ FinalAt(a, k)

FixedFinal == \A k \in fixed : FinalAt(a, k)
SortedAtEnd == Done => Sorted(a)
Terminates == <>Done
=============================================================================
