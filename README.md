# Verifikacija algoritama sortiranja u TLA+

Repozitorijum sadrži specifikacije i verifikaciju šest algoritama sortiranja za
kurs Formalne metode na doktorskim studijama Matematičkog fakulteta. TLA+ modeli
opisuju korake algoritama i svojstva koja se proveravaju pomoću TLC-a, a C++20
implementacije predstavljaju izvršive reference.

Predmet sortiranja su konačni nizovi celih brojeva, uključujući prazne nizove,
negativne vrednosti i ponavljanja. Za svaki algoritam razmatraju se očuvanje
višestrukosti elemenata, ispravnost pristupa nizu, terminacija i uređenost izlaza.
Za stabilne algoritme proverava se i očuvanje relativnog redosleda jednakih
vrednosti.

## Algoritmi

Neka je `n` dužina ulaznog niza. Prostorna složenost označava dodatnu memoriju
C++ implementacije; kod quicksort-a uključuje stek rekurzije.

| Algoritam i dokumentacija | Implementirana varijanta | Vremenska složenost | Dodatni prostor | Stabilan |
| --- | --- | --- | --- | --- |
| [Quicksort](quicksort/README.md) | Nasumični pivot, trostruka particija, rekurzija nad manjim delom | O(n log n) očekivano, O(n²) najgore | O(log(n+1)) | Ne |
| [Sortiranje umetanjem](insertion_sort/README.md) | Sačuvani ključ i pomeranje elemenata | O(n) najbolje, O(n²) najgore | O(1) | Da |
| [Sortiranje izborom](selection_sort/README.md) | Prvi minimum, bez zamene elementa sa samim sobom | Θ(n²), najviše n−1 zamena za n ≥ 1 | O(1) | Ne |
| [Sortiranje spajanjem](merge_sort/README.md) | Iterativno spajanje odozdo nagore, jedan pomoćni niz | Θ(n log n) | O(n) | Da |
| [Mehurasto sortiranje](bubble_sort/README.md) | Smanjivanje granice, izlaz nakon prolaza bez zamena | O(n) najbolje, O(n²) najgore | O(1) | Da |
| [Sortiranje hipom](heap_sort/README.md) | Izgradnja odozdo nagore, iterativna popravka | O(n) izgradnja, O(n log n) sortiranje najgore | O(1) | Ne |

## Struktura repozitorijuma

Svaki direktorijum algoritma sadrži `README.md`, C++ zaglavlje `.hpp`, TLA+ modul
`.tla` i TLC konfiguraciju `.cfg`. Dokumentacija algoritma navodi modelovane
korake, proveravana svojstva, složenost, vezu sa implementacijom i
komande za proveru.

| Putanja | Sadržaj |
| --- | --- |
| [common/SortProperties.tla](common/SortProperties.tla) | Zajedničke definicije permutacije, uređenosti, konačnih pozicija i stabilnosti |
| [common/README.md](common/README.md) | Zajednički operatori, obim provera i komande |
| [quicksort/Partition.tla](quicksort/Partition.tla) | Poseban modul za korake i invarijantu particije |
| [quicksort/test.cpp](quicksort/test.cpp) | C++ provere quicksort-a i particionisanja |
| [tests/sorts.cpp](tests/sorts.cpp) | C++ provere ostalih pet algoritama |
| [selection_sort/Unstable.cfg](selection_sort/Unstable.cfg), [heap_sort/Unstable.cfg](heap_sort/Unstable.cfg) | Posebne konfiguracije za kontraprimere stabilnosti |
| [Makefile](Makefile) | Prevođenje testova, pokretanje TLC-a i provera očekivanih kontraprimera |
| [AGENTS.md](AGENTS.md) | Pravila rada u repozitorijumu |

## Obim verifikacije

Projekat obuhvata sledeće provere i objašnjenja:

1. **TLC provera konačnog domena.** Svaka redovna konfiguracija obuhvata svih
   1.093 ulaza dužine 0–6 nad `{-1, 0, 1}` i proverava navedene invarijante i
   `Terminates`. Quicksort obuhvata sve modelovane izbore pivota. Posebne
   konfiguracije daju kontraprimere stabilnosti sortiranja izborom i hipom.
2. **Objašnjenja modela.** README datoteke algoritama opisuju promenljive,
   korake izvršavanja, značenje proveravanih svojstava i složenost. Ova objašnjenja
   nisu opšti matematički dokazi korektnosti i terminacije.
3. **C++ provere i objašnjena korespondencija.** Izvršive implementacije porede
   se sa `std::sort` i proveravaju uz sanitizatore. Dokumentovana veza koraka
   modela sa kodom nije mašinski provereni dokaz rafinacije C++ programa.

TLA+ modeli koriste neograničene cele brojeve; C++ API prihvata vrednosti tipa
`int`. Prolazak TLC provera ne dokazuje svojstva za proizvoljne dužine i
vrednosti van proverenog domena. Modeli stabilnost prate pomoću početnih indeksa elemenata. Ti identiteti
nisu deo C++ API-ja. Očekivana složenost quicksort-a pretpostavlja uniforman
izbor pivota i nije rezultat probabilističke TLC provere.

## Pokretanje provera

Potrebni su C++20 prevodilac sa podrškom za AddressSanitizer i
UndefinedBehaviorSanitizer, GNU Make, Bash, Java i `tla2tools.jar`. Detalji
pokretanja navedeni su u [zajedničkoj dokumentaciji](common/README.md#reprodukcija).
JAR se može uzeti i iz instaliranog TLA+ proširenja za VS Code.

Iz korena repozitorijuma, sa apsolutnom putanjom do JAR datoteke:

```sh
make check TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Odvojeno pokretanje grupa provera:

```sh
make test
make models TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
make selection-witness heap-witness TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

`make check` uspeva kada prođu C++ testovi i svi redovni modeli, a obe posebne
konfiguracije prijave očekivano narušavanje `StableAtEnd`. Podrazumevani izlazni
direktorijum je `/tmp/tla-plus-checks`; može se promeniti parametrom `BUILD_DIR`.
Pojedinačni ciljevi i detalji izvršavanja nalaze se u
[zajedničkoj dokumentaciji](common/README.md).
