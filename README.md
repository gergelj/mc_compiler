# Kompajler za proširen MiniC jezik

## Fajlovi:

### `semantic.l`

Specifikacija za skener teksta (flex).

Unutar se nalaze regularni izrazi simbola proširenog MiniC jezika.

### `semantic.y`

Specifikacija za parser teksta (bison).

Unutar se nalazi formalna gramatika proširenog MiniC jezika.

Takođe, ovde se nalaze i semantička pravila jezika.

### `defs.h`

Ovaj fajl sadrži tipove podataka, simbola odnosno tipove nekih tokena (AROPS, RELOPS itd.).

### `symtab.c` i `symtab.h`

Tabela simbola i njene metode. Opis metoda za upravljanje tabelom se nalazi u `symtab.h` fajlu.

### `Makefile`

Fajl za generisanje izvršnog programa (skener-parser).

### `test-sanity1.mc`

Test primer na MiniC jeziku. Ovaj test mora da prođe svaki put, tu su granični slučaji pravila polaznog MiniC jezika.

## Makefile

Kompajliranje datoteka da bismo dobili izvršni fajl `semantic`

```
make
```

Brisanje iskompajliranih fajlova:

```
make clean
```

Pokretanje test primera:

```
make test
```

Detaljniji prikaz test primera:

```
make det
```

Test fajlovi moraju da budu u tekućem folderu, pri čemu ime datoteke za primere koji su pravilni treba da počinju sa `test-ok`..`.mc`, koji imaju semantičku grešku `test-semerr`..`.mc`, a koji imaju sintaksnu grešku sa `test-synerr`..`.mc`.

Svi testovi moraju da prođu (PASSED).

## Proširenje u odnosu na MiniC jezik

1. Jednolinijski komentar (`//`) i blok komentar (`/* */`)
2. DO-WHILE iskaz (uslovni izraz može da bude sastavljen od više relacionih izraza spojeni sa logičkim operatorima) Npr:

```c
do 
...
while( a > b && (c <= 4) && (d == e) )
```
3. Deklaracija više promenljive u jednoj liniji

```c
int a, b, c;
```

4. Postinkrement operator u iskazima i u izrazima.
5. Uslovni izraz u IF iskazu isto se može zapisati kao kod DO-WHILE.
6. FOR iskaz (Basic)

```c
"for" <id1> "=" <const1> <direction> <const2> [ "step" <const3> ]
        <statement>
    "next" <id2>
```

```c
for i = 1 to 9
    ...
next i

for j = 10 downto 0 step 2
    ...
next j
```

7. Višestruka dodela.

```c
a = b = c = d = e + 5;
```

8. Tip VOID kao povratni tip funkcije.
9. RETURN iskaz

| tip f-je:    |  void   | int/unsigned |
| ------------ |:-------:|:------------:|
| return exp ; |  error  |     OK		|
|   return ;   |   OK    |  warning		|
|  bez return  |   OK    |  warning		|

10. Definicija promenljivih u ugnježdenim blokovima.
11. SWITCH iskaz. (Ne sme ugnježdeni SWITCH iskaz - SWITCH u SWITCH-u)
12. FOR iskaz.

```c
"for" "(" <type> <id1> "=" <lit> ";" <relation> ";" <id2> "++" ")"
     <stmt>
```

\<id1\> treba da bude lokalna promenljiva za for iskaz.
