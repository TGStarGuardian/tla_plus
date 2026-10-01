# Insertion sort

Insertion sort uzima jedan element i umeće ga na odgovarajuće mesto u već
sortiranom levom delu niza. Veće elemente pomera udesno, a zatim upisuje sačuvani
ključ. Jednaki elementi se ne pomeraju preko ključa, pa je sortiranje stabilno.

## Datoteke i interfejs

| Datoteka | Uloga |
| --- | --- |
| [insertion_sort.hpp](insertion_sort.hpp) | C++20 implementacija, `void insertion_sort::sort(std::span<int>)` |
| [InsertionSort.tla](InsertionSort.tla) | Koraci umetanja i svojstva |
| [InsertionSort.cfg](InsertionSort.cfg) | TLC konfiguracija |
| [../tests/sorts.cpp](../tests/sorts.cpp) | C++ provere |

## Model i veza sa C++ kodom

Stanje modela dato je sledećim elementima:

1. `original` je početni niz;
2. `a` je trenutni niz početnih indeksa elemenata;
3. `i` je pozicija elementa koji trenutno umećemo;
4. `j` je pozicija na koju trenutno možemo upisati ključ;
5. `key` je sačuvani indeks elementa koji umećemo;
6. `phase` je trenutna faza izvršavanja.

Model prati sledeće korake C++ petlji:

1. `Init` postavlja početni raspored i bira drugi element za prvo umetanje;
2. `Load` čuva element na poziciji `i` u `key` i postavlja `j` na tu poziciju;
3. `Compare` proverava da li postoji prethodnik i da li je veći od ključa;
4. `Shift` pomera većeg prethodnika udesno, smanjuje `j` i vraća se na poređenje;
5. `Place` upisuje ključ kada je pronađeno njegovo mesto i prelazi na sledeće `i`.

`Done` označava da su obrađeni svi elementi. Prazan i jednočlani niz odmah
zadovoljavaju ovaj uslov. C++ indeksi `i` i `j` manji su za jedan od modelovih.

Tokom pomeranja u nizu može privremeno postojati duplikat, dok je ključ sačuvan
odvojeno. Izraz `Live` zato posmatra niz kao da je na poziciji `j` sačuvani ključ.
To omogućava praćenje svih elemenata i pre završnog upisa.

## Proveravana svojstva

Svojstva koja se proveravaju su sledeća:

1. `TypeOK` proverava dozvoljene vrednosti promenljivih i faza;
2. `AccessSafety` proverava granice `i` i `j`, validnost ključa i da se pomera
   samo postojeći prethodnik koji je veći od ključa;
3. `PreservesElements` proverava da `Live` sadrži sve početne elemente, svaki
   tačno jednom;
4. `StableOrder` proverava da jednaki elementi zadržavaju početni redosled;
5. `PrefixCorrect` proverava da je pre sledećeg umetanja levi deo stabilno
   sortiran i sadrži upravo elemente početnog prefiksa, a ostatak nije promenjen;
6. `ShiftInvariant` proverava da tokom umetanja deo bez praznine ostaje stabilno
   sortiran, da su pomereni elementi veći od ključa i da ključ na kraju može
   stati iza svog prethodnika; elementi posle `i` ostaju netaknuti;
7. `SortedAtEnd` proverava da je ceo niz stabilno sortiran kada važi `Done`;
8. `Terminates` proverava da algoritam na kraju stigne do `Done`.

## Složenost

Na već sortiranom nizu svaki ključ odmah ostaje na svom mestu, pa je vreme O(n).
U najgorem slučaju svaki ključ prolazi kroz ceo dotad obrađeni deo, što daje
O(n²). Čuvaju se samo ključ i indeksi, pa je dodatni prostor O(1).

## Pokretanje i rezultati provera

Iz korena repozitorijuma:

```sh
make test
make insertion-model TLA_TOOLS_JAR=/apsolutna/putanja/do/tla2tools.jar
```

Zajedničke definicije, opseg provera i način pokretanja opisani su u
[zajedničkoj dokumentaciji](../common/README.md).
