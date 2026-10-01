# Merge sort

Merge sort spaja susedne sortirane blokove u veće sortirane blokove. Počinje
blokovima od jednog elementa, zatim obrađuje širine 2, 4 i tako dalje. Spojeni
blok prvo upisuje u pomoćni niz, pa ga kopira nazad. Pri jednakim vrednostima
uzima levi element, pa je sortiranje stabilno.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [merge_sort.hpp](merge_sort.hpp) | C++20 implementacija, `void merge_sort::sort(std::span<int>)` |
| [MergeSort.tla](MergeSort.tla) | Koraci spajanja i svojstva |
| [MergeSort.cfg](MergeSort.cfg) | TLC konfiguracija |
| [../tests/sorts.cpp](../tests/sorts.cpp) | C++ provere |

## Model i veza sa C++ kodom

Stanje modela dato je sledećim elementima:

1. `original` je početni niz;
2. `a` je trenutni niz početnih indeksa elemenata;
3. `buffer` je pomoćni niz u koji se upisuje rezultat spajanja;
4. `source` je snimak niza pre tekućeg spajanja, koji model koristi za proveru;
5. `width` je širina blokova koji se trenutno spajaju;
6. `lo`, `mid` i `hi` ograničavaju levi blok `[lo, mid)` i desni `[mid, hi)`;
7. `left` i `right` pokazuju sledeće nepreuzete elemente levog i desnog bloka;
8. `out` je sledeća pozicija za upis u pomoćni niz;
9. `chosen` je pozicija elementa izabranog za taj upis;
10. `copy` je pozicija koja se trenutno kopira nazad u `a`;
11. `phase` je trenutna faza izvršavanja.

Model prati sledeće korake C++ petlji:

1. `Init` postavlja početni raspored i širinu blokova na jedan;
2. `BeginMerge` određuje granice sledeća dva bloka i postavlja pokazivače;
3. `Compare` bira manji od sledećih elemenata; na jednakost bira levi, a ako je
   jedan blok potrošen, bira iz drugog;
4. `Write` upisuje izabrani element u `buffer` i pomera odgovarajuće pokazivače;
5. `BeginCopy` počinje povratno kopiranje kada su oba bloka potrošena;
6. `Copy` kopira jedan element u `a`; posle poslednjeg upisa prelazi se na
   sledeći par blokova;
7. `NextPass` posle celog prolaza povećava širinu i ponovo kreće od početka niza.

`Done` važi kada širina dostigne dužinu niza; tada više nema odvojenih blokova
za spajanje. Prazan i jednočlani niz odmah su završeni. Model završnu širinu
postavlja na dužinu niza, dok C++ na tom mestu izlazi iz petlje. Granice i
pokazivači u C++ kodu manji su za jedan; `width` ima istu vrednost.

`source` nije dodatna kopija u C++ implementaciji. Tokom povratnog kopiranja
izraz `Live` uzima ceo spojeni blok iz `buffer`, a ostatak iz `a`. Tako delimično
prepisivanje ulaznog niza ne izgleda kao gubitak ili dodavanje elemenata.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava dozvoljene vrednosti promenljivih i faza;
2. `MergeShape` proverava granice blokova i pokazivača, broj preuzetih elemenata
   i početnu stabilnu uređenost blokova koji se spajaju;
3. `AccessSafety` proverava da se biraju postojeći elementi i upisuje unutar
   tekućeg bloka;
4. `ArrayFrame` proverava da je tokom spajanja `a` nepromenjen, a tokom povratnog
   kopiranja promenjen samo već prepisani deo, u skladu sa `buffer`;
5. `PreservesElements` proverava da `Live` sadrži sve početne elemente tačno jednom;
6. `StableOrder` proverava da jednaki elementi u `Live` zadržavaju početni redosled;
7. `RunInvariant` proverava uređenost blokova: završeni deo prolaza ima spojene
   blokove dvostruke širine, a preostali deo blokove tekuće širine;
8. `MergePrefix` proverava da upisani deo pomoćnog bloka sadrži upravo preuzete
   elemente, stabilno sortirane, i da dolaze pre svih još nepreuzetih elemenata;
9. `SortedAtEnd` proverava da je ceo niz stabilno sortiran kada važi `Done`;
10. `Terminates` proverava da algoritam na kraju stigne do `Done`.

## Složenost

U jednom prolazu svaki element se upisuje u pomoćni niz i zatim vraća u ulazni
niz. To zahteva O(n) vremena. Širina se udvostručava, pa ima O(log n) prolaza,
a ukupno vreme je Θ(n log n), i za već sortiran ulaz. Jedan pomoćni niz ponovo
se koristi pri svakom spajanju, pa je dodatni prostor O(n). Nema rekurzije.

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make merge-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
