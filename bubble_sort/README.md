# Bubble sort

Bubble sort zamenjuje susedne elemente samo kada je levi
strogo veći. U svakoj narednoj iteraciji, prolazi se kroz sve manji deo početnog niza.
U slučaju da se nijedna zamena ne izvrši, algoritam se zaustavlja i niz se smatra sortiranim.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [bubble_sort.hpp](bubble_sort.hpp) | C++20 implementacija, `void bubble_sort::sort(std::span<int>)` |
| [BubbleSort.tla](BubbleSort.tla) | Koraci poređenja, zamene i prolaza |
| [BubbleSort.cfg](BubbleSort.cfg) | TLC konfiguracija |
| [../tests/sorts.cpp](../tests/sorts.cpp) | C++ provere |

## Model i veza sa C++ kodom

TLA+ poziciji `k` odgovara C++ indeks `k-1`. Modelov `i` označava levi element
poređenog para, dok C++ `i` označava desni: `a[i-1]` i `a[i]`.
Modelov `bound` je jednak granici `end` u C++.

Stanje modela dato je sledećim elementima:

1. početni niz, `original`;
2. trenutni niz indeksa, `a`;
3. trenutni indeks, `i`;
4. trenutna faza izvršavanja algoritma, `phase`;
5. trenutna gornja granica podniza koji se sortira, `bound`;
6. da li je neka razmena izvršena, `swapped`.

Model prati sledeće korake C++ petlji:

1. `Init` postavlja početno stanje;
2. `Start` započinje prolaz od početka niza i postavlja `swapped` na netačno;
3. `Compare` poredi susedne vrednosti;
4. `Exchange` zamenjuje ih ako je leva strogo veća i beleži da je bilo zamene;
5. `Advance` prelazi na naredni par ili završava prolaz;
6. `Finish` završava algoritam ako nije bilo zamena, a inače smanjuje granicu
   i priprema sledeći prolaz;
7. `Stop` završava algoritam kada preostali deo ima najviše jedan element.

`Done` je uslov koji označava da je algoritam završen. Do njega se dolazi preko
`Finish` nakon prolaza bez zamena ili preko `Stop` kada je preostali deo dovoljno
mali. Prazan i jednočlani niz završavaju se preko `Stop`, bez poređenja.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava da svi elementi stanja imaju dozvoljene vrednosti;
2. `AccessSafety` proverava da indeks `i` dozvoljava pristup susednom paru tokom
   poređenja, zamene i pomeranja; u fazi zamene levi element mora biti veći,
   a na kraju prolaza indeks mora dostići granicu veću od jedan;
3. `PreservesElements` proverava da je niz `a` permutacija niza `1, 2, 3, ..., N`;
4. `StableOrder` proverava da jednaki elementi zadržavaju početni redosled;
5. `SuffixFinal` proverava da su pozicije iza trenutne granice već na svojim
   konačnim mestima u sortiranom nizu;
6. `ScanMaximum` proverava da svaki korak prolaza prenosi najveću vrednost
   pregledanog dela na njegovu desnu granicu;
7. `PassFinal` proverava da je na kraju prolaza element na `bound` dostigao
   svoju konačnu poziciju;
8. `NoSwapsSorted` proverava da je niz sortiran ako u završenom prolazu nije
   bilo zamene;
9. `SortedAtEnd` proverava da je niz stabilno sortiran kada važi `Done`;
10. `Terminates` proverava da algoritam na kraju stigne do `Done`.

## Složenost

Na uređenom ili potpuno jednakom ulazu prvi prolaz košta O(n) i završava rad.
Najgori slučaj ima `(n-1)+(n-2)+...+1` poređenja i O(n²) zamena, pa vreme iznosi
O(n²). Indeksi, privremena vrednost zamene i oznaka zahtevaju O(1) dodatnog
prostora. Nema alokacije ni rekurzije.

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make bubble-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
