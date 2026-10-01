# Quicksort

Quicksort bira pivot i deli niz na vrednosti manje od njega, jednake njemu i
veće od njega. Jednaki deo je tada na konačnim sortiranim pozicijama. Preostala
dva dela obrađuju se na isti način. C++ implementacija rekurzivno obrađuje manji
deo, a veći nastavlja petljom. Sortiranje nije stabilno.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [quicksort.hpp](quicksort.hpp) | Javni API, particija i sortiranje |
| [Partition.tla](Partition.tla) | Invarijanta i koraci particije |
| [Quicksort.tla](Quicksort.tla) | Izbor pivota, izvršavanje particije i preostali posao |
| [Quicksort.cfg](Quicksort.cfg) | Invarijante i terminacija za konačan domen |
| [test.cpp](test.cpp) | Izvršive provere sortiranja i ugovora particije |

## Model i veza sa C++ kodom

Stanje modela dato je sledećim elementima:

1. `original` je početni niz;
2. `a` je trenutni niz vrednosti;
3. `pending` je niz podintervala koji još čekaju obradu;
4. `fixed` je skup pozicija koje su već završene;
5. `phase` razlikuje čekanje zadatka (`idle`), particionisanje (`scan`) i
   završenu particiju (`split`);
6. `lo` i `hi` ograničavaju podinterval koji se obrađuje, pri čemu `hi` ne pripada
   tom podintervalu;
7. `lt` označava kraj dela sa manjim vrednostima i početak jednakog dela;
8. `scan` je sledeća pozicija čiju vrednost treba razvrstati;
9. `gt` označava početak dela sa većim vrednostima;
10. `pivot` je kopirana vrednost izabrana iz tekućeg podintervala.

Model prati sledeće korake C++ implementacije:

1. `Init` postavlja ceo niz kao prvi zadatak, osim ako ima najviše jedan element;
2. `Start` uzima sledeći zadatak, bira pivot i postavlja granice particije;
3. `Scan` izvršava jednu iteraciju particionisanja pomoću `PartitionStep` iz
   `Partition.tla`;
4. `Finish` označava jednaki blok kao završen i stavlja manji pa veći preostali
   deo na početak `pending`; prazni delovi se preskaču, a jednočlani odmah završavaju.

Jedan korak `Scan` ima tri mogućnosti:

1. ako je element manji od pivota, zamenjuje se sa elementom na `lt`, pa se
   povećavaju `lt` i `scan`;
2. ako je veći, smanjuje se `gt` i vrši zamena sa tom pozicijom; `scan` ostaje
   na mestu jer pristigli element tek treba razvrstati;
3. ako je jednak pivotu, samo se povećava `scan`.

Kada `scan` stigne do `gt`, nema više nerazvrstanih elemenata i sledi `Finish`.
`Done` važi kada nema ni aktivne particije ni preostalih zadataka.

C++ granice i pokazivači manji su za jedan od modelovih. `pending` predstavlja
redosled poslova koji u C++ kodu nastaje iz rekurzivnih poziva i petlje; `fixed`
postoji samo radi provere. C++ prima generator `std::mt19937&` i bira nasumičan
indeks pivota. Model bira nedeterministički, pa TLC razmatra sve modelovane izbore
bez dodeljivanja verovatnoća.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava dozvoljene vrednosti promenljivih i faza;
2. `PreservesValues` proverava da niz ima iste vrednosti i isti broj njihovih
   pojavljivanja kao na početku;
3. `Separated` proverava da vrednosti pre nezavršenog podintervala nisu veće
   od njegovih vrednosti, a vrednosti posle njega nisu manje;
4. `WorkCoverage` proverava da nezavršeni podintervali i završene pozicije
   pokrivaju ceo niz bez preklapanja;
5. `PartitionCorrect` proverava granice i raspored: manji elementi su pre `lt`,
   jednaki između `lt` i `scan`, neobrađeni između `scan` i `gt`, a veći od `gt`
   do `hi`; pivot ostaje prisutan u tekućem podintervalu;
6. `AccessSafety` proverava da se pri razvrstavanju pristupa postojećim
   pozicijama i da su `scan` i `gt` jednaki nakon particije;
7. `PivotFinal` proverava da je posle cele particije jednaki blok neprazan i da
   su njegove vrednosti već na konačnim sortiranim pozicijama;
8. `FixedFinal` proverava da sve označene završene pozicije ostaju konačne;
9. `SortedAtEnd` proverava da je ceo niz sortiran kada važi `Done`;
10. `Terminates` proverava da algoritam na kraju stigne do `Done`.

## Složenost

Particionisanje podintervala dužine `m` zahteva O(m) vremena. Uz uniforman izbor
indeksa pivota očekivano vreme sortiranja je O(n log n). Uz stalno nepovoljne
pivote može biti O(n²). Ako su sve vrednosti jednake, dovoljna je jedna linearna
particija. TLC ne proverava očekivanu vremensku složenost.

Rekurzivno se obrađuje samo manji deo, koji ima najviše polovinu preostalih
elemenata. Zato dubina steka iznosi O(log(n+1)) i pri nepovoljnim pivotima.
Po pozivu se čuva nekoliko indeksa i pivot; nema pomoćnog niza.

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make quicksort-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
