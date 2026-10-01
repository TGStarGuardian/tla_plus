# Heap sort

Heap sort prvo gradi maksimalni hip: svaki roditelj ima vrednost bar jednaku
vrednostima svoje dece, pa je najveći element u korenu. Zatim taj element
premešta na kraj, smanjuje hip i popravlja njegov koren. Ponavljanjem raste
sortirani desni deo niza. Sortiranje nije stabilno.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [heap_sort.hpp](heap_sort.hpp) | C++20 implementacija, `void heap_sort::sort(std::span<int>)` |
| [HeapSort.tla](HeapSort.tla) | Izgradnja, popravka i izdvajanje maksimuma |
| [HeapSort.cfg](HeapSort.cfg) | Redovna TLC konfiguracija |
| [Unstable.cfg](Unstable.cfg) | Kontraprimer stabilnosti |
| [../tests/sorts.cpp](../tests/sorts.cpp) | C++ provere |

## Model i veza sa C++ kodom

Stanje modela dato je sledećim elementima:

1. `original` je početni niz;
2. `a` je trenutni niz početnih indeksa elemenata;
3. `size` je broj elemenata koji još pripadaju hipu;
4. `build` je sledeći koren podstabla koje popravljamo tokom izgradnje hipa;
5. `root` je koren tekuće popravke;
6. `hole` je pozicija privremene praznine u koju možemo pomeriti dete;
7. `saved` je indeks elementa sačuvanog na početku popravke;
8. `child` je pozicija deteta koje razmatramo za pomeranje;
9. `mode` razlikuje izgradnju hipa (`build`) od sortiranja (`sort`);
10. `phase` je trenutna faza popravke ili spremnost za sledeću operaciju.

Model prati sledeće korake C++ implementacije:

1. `Init` postavlja početni raspored i započinje izgradnju od poslednjeg čvora
   koji ima decu;
2. `StartBuild` čuva element tog čvora u `saved` i započinje popravku;
3. `FindChildren` proverava da li praznina ima dete; ako nema, sledi završni upis;
4. `SelectChild` bira veće dete, a pri jednakosti levo;
5. `Compare` poredi sačuvanu vrednost sa izabranim detetom; ako nije manja,
   može se upisati, a inače dete treba pomeriti naviše;
6. `Move` kopira dete u prazninu, pa se praznina pomera na staro mesto deteta
   i ponovo se traže njena deca;
7. `Place` upisuje sačuvani element; tokom izgradnje prelazi se na prethodni koren;
8. `Built` po završetku izgradnje prelazi na sortiranje;
9. `Extract` zamenjuje koren sa poslednjim elementom hipa, smanjuje `size` i
   započinje popravku novog korena koracima od `FindChildren` do `Place`.

`Done` važi u režimu sortiranja kada je popravka završena i u hipu ostaje
najviše jedan element. Prazan i jednočlani niz prolaze samo kroz prelazak
`Built`, bez popravki i zamena.

Deca čvora `p` u modelu su na pozicijama `2*p` i `2*p+1`, ako pripadaju hipu.
C++ pozicije su manje za jedan, dok je `size` jednak C++ granici `end`.
Koraci popravke odgovaraju funkciji `sift_down`. Izraz `Live` posmatra prazninu
kao da sadrži `saved`, pa čuva pregled svih elemenata i dok fizički niz ima
duplikat zbog kopiranja deteta.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava dozvoljene vrednosti promenljivih, režima i faza;
2. `AccessSafety` proverava da koren, praznina i izabrano dete pripadaju hipu,
   da je sačuvani element validan i da su indeksi usklađeni sa fazom popravke;
3. `PreservesElements` proverava da `Live` sadrži sve početne elemente tačno jednom;
4. `BuiltSubtrees` proverava da su tokom izgradnje već obrađeni čvorovi iza
   `build` pravilno uređeni prema svojoj deci;
5. `HeapAtBoundary` proverava da je pre sledećeg izdvajanja preostali deo niza hip;
6. `RepairInvariant` proverava da tokom popravke obrađeni roditelji od `root`
   nadalje, osim praznine, zadovoljavaju poredak hipa; ako je praznina spuštena,
   njen roditelj mora biti dovoljno velik da ispod njega može doći bilo koje
   njeno dete;
7. `ChildCorrect` proverava da je izabrano veće dete, levo pri jednakosti, i
   da se dete pomera naviše samo kada je veće od sačuvane vrednosti;
8. `ReadyToPlace` proverava da sačuvana vrednost može stati u prazninu bez
   narušavanja odnosa prema deci;
9. `SuffixFinal` proverava da su pozicije iza hipa već na svojim konačnim mestima;
10. `SortedAtEnd` proverava da je ceo niz sortiran kada važi `Done`;
11. `Terminates` proverava da algoritam na kraju stigne do `Done`.

Posebna konfiguracija `Unstable.cfg` proverava `StableAtEnd` i očekuje
kontraprimer. Dovoljna su dva jednaka elementa sa različitim početnim identitetima:

```text
ulaz i izgrađeni hip:   0₁  0₂
posle izdvajanja:       0₂  0₁
```

Zamena korena sa poslednjim elementom obrće njihov redosled.

## Složenost

Izgradnja hipa odozdo nagore zahteva O(n) vremena: mnogo čvorova je blizu listova
i zahteva kratku popravku, dok samo mali broj može prolaziti kroz više nivoa.
Svako kasnije izdvajanje zahteva najviše O(log n) vremena za popravku, pa je
najgore vreme sortiranja O(n log n). Čuvaju se jedna vrednost i nekoliko indeksa,
pa je dodatni prostor O(1). Nema rekurzije ni pomoćnog niza.

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make heap-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
make heap-witness TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
