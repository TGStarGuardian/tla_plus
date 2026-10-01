# Zajedničke definicije i provere

[SortProperties.tla](SortProperties.tla) sadrži svojstva nizova koja koriste
modeli svih šest algoritama. Prelazi algoritama definisani su u njihovim
zasebnim modulima. Pregled projekta nalazi se u [glavnom README-u](../README.md).

## Definicije

| Operator | Značenje |
| --- | --- |
| `Indices(lo, hi)` | Indeksi poluotvorenog intervala `[lo, hi)` |
| `Swap(a, i, j)` | Niz dobijen zamenom elementa na indeksu `i` sa elementom na indeksu `j` |
| `Values(a)`, `Count(a, v)` | Skup vrednosti niza i broj pojavljivanja svake vrednosti |
| `Permutation(a, b)` | Niz `a` je permutacija niza `b` ako i samo ako su jednake dužine i imaju iste vrednosti isti broj puta |
| `Sorted(a)` | Uslov da je `a` sortiran, što znači da je uređen neopadajućim poretkom |
| `FinalAt(a, k)` | Element na indeksu `k` je na svojoj pravoj poziciji nakon sortiranja |
| `Min(x, y)` | Izraz koji vraća `x` ako je on manji od `y`, a inače vraća `y` |
| `Identity(n)` | Niz elemenata `1, 2, 3, ..., n` |
| `Keys(order, original)` | `order` skladišti permutovani niz indeksa od `original`, a ovo je niz koji se dobija kada se indeksi od `original` permutuju u skladu sa `order` |
| `KeySorted(order, original)` | Uslov da je `original` permutovan u skladu sa `order` sortiran |
| `Stable(order, original)` | Uslov da je niz `original` stabilan u odnosu na `order` |
| `StableSorted(order, original)` | Uslov da je niz stabilan u odnosu na `order` i da je sortiran |
| `Before(x, y, original)` | Uslov da su elementi na indeksima `x` i `y` sortirani |
| `RunsSorted(order, original, width)` | Uslov koji tvrdi da su uzastopni blokovi dužine `width` stabilno sortirani, uz mogućnost da je poslednji blok kraći od `width` |

## Šta smo testirali

Proverili smo algoritme za sve nizove dužine od 0 do 6 nad skupom `{-1, 0, 1}`.  Takvih nizova ima ukupno 1093. Time su obuhvaćeni prazan niz, jednočlani nizovi,
negativne vrednosti i ponavljanja.
Quicksort istražuje i sve izbore pivota.

## Reprodukcija

Iz korena repozitorijuma, uz C++20 kompilator sa sanitizatorima, GNU Make, Bash,
Java i TLA+ tools JAR:

```sh
make test
make models TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
make selection-witness heap-witness TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
# Sve provere:
make check TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Pojedinačni ciljevi su `quicksort-model`, `insertion-model`, `selection-model`,
`merge-model`, `bubble-model` i `heap-model`. `Makefile` postavlja `TLA-Library`
na direktorijum `common`. Za neposredno pokretanje Java komandom ili kroz IDE
potrebna je JVM opcija `-DTLA-Library=/apsolutna/putanja/do/repozitorijuma/common`.

Programi i TLC dnevnici podrazumevano se smeštaju u `/tmp/tla-plus-checks`.
`BUILD_DIR` omogućava izbor druge apsolutne putanje. C++ testovi koriste aktivne
asercije, AddressSanitizer i UndefinedBehaviorSanitizer; prevodilac se bira
parametrom `CXX`. Za korišćenje zaglavlja van testova može se koristiti `-O3`.

Ciljevi `selection-witness` i `heap-witness` namerno proveravaju netačno svojstvo
`StableAtEnd`. Uspevaju samo ako TLC vrati kod 12 i prijavi upravo narušavanje
te invarijante; greška alata ne predstavlja uspešnu proveru. Tragovi su u
`selection-witness.log` i `heap-witness.log`. Redovne konfiguracije ova dva
algoritma ne zahtevaju stabilnost.
