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



### `test-sanity1.mc`

## Makefile


