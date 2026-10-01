# Selection sort

Selection sort u preostalom delu niza pronalazi prvi najmanji element i postavlja
ga na početak tog dela. Posle svake iteracije još jedna pozicija je završena.
Ako je minimum već na pravom mestu, zamena se preskače. Sortiranje nije stabilno.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [selection_sort.hpp](selection_sort.hpp) | C++20 implementacija, `void selection_sort::sort(std::span<int>)` |
| [SelectionSort.tla](SelectionSort.tla) | Koraci izbora i svojstva |
| [SelectionSort.cfg](SelectionSort.cfg) | Redovna TLC konfiguracija |
| [Unstable.cfg](Unstable.cfg) | Kontraprimer stabilnosti |
| [../tests/sorts.cpp](../tests/sorts.cpp) | C++ provere |

## Model i veza sa C++ kodom

Stanje modela dato je sledećim elementima:

1. `original` je početni niz;
2. `a` je trenutni niz početnih indeksa elemenata;
3. `i` je pozicija koju trenutno popunjavamo minimumom;
4. `cursor` je pozicija sledećeg kandidata za minimum;
5. `minimum` je pozicija prvog najmanjeg elementa pronađenog do sada;
6. `phase` je trenutna faza izvršavanja.

Model prati sledeće korake C++ petlji:

1. `Init` postavlja početni raspored i kreće od prve pozicije;
2. `Start` uzima element na `i` kao početni minimum i postavlja `cursor` iza njega;
3. `Compare` poredi kandidata sa minimumom, menja minimum samo ako je kandidat
   strogo manji i pomera `cursor`;
4. `EndScan` završava pretragu kada više nema kandidata;
5. `Exchange` zamenjuje elemente na `i` i `minimum`, ako su pozicije različite,
   pa prelazi na sledeće `i`.

`Done` važi kada je preostao najviše jedan element. Prazan i jednočlani niz odmah
su završeni. Pozicijama `i`, `cursor` i `minimum` odgovaraju C++ indeksi manji
za jedan; C++ unutrašnja petlja koristi ime `j` umesto `cursor`.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava dozvoljene vrednosti promenljivih i faza;
2. `AccessSafety` proverava granice pretrage i da zamena sledi tek posle
   pregledanja celog preostalog dela;
3. `PreservesElements` proverava da nijedan početni element nije izgubljen ili
   dodat;
4. `MinimumCorrect` proverava da `minimum` pokazuje na prvo pojavljivanje
   najmanje vrednosti u pregledanom delu;
5. `PrefixFinal` proverava da su sve pozicije pre `i` već na svojim konačnim
   mestima u sortiranom nizu;
6. `SortedAtEnd` proverava da je niz sortiran kada važi `Done`;
7. `Terminates` proverava da algoritam na kraju stigne do `Done`.

Posebna konfiguracija `Unstable.cfg` proverava `StableAtEnd` i očekuje
kontraprimer. Brojevi u indeksu prikazuju početni identitet elementa:

```text
ulaz:               1₁  1₂  0₃
posle prve zamene:   0₃  1₂  1₁
izlaz:              0₃  1₂  1₁
```

Prvi element pri zameni prelazi preko jednakog elementa. Zato izbor prvog
minimuma nije dovoljan da sortiranje bude stabilno.

## Složenost

Svaka iteracija pregleda ceo preostali deo. Ukupno ima `n(n-1)/2` poređenja,
pa je vreme Θ(n²), čak i za već sortiran niz. Za neprazan niz izvršava se najviše
`n-1` zamena. Dodatni prostor je O(1).

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make selection-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
make selection-witness TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
