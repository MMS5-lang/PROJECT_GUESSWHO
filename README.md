# PROJECT_GUESSWHO

Repozytorium zawiera implementację gry Guess Who dla dwóch płytek Digilent
Basys 3. Każda płytka obsługuje własny ekran VGA, mysz PS/2 i komunikuje się z
drugą płytką przez UART wyprowadzony na złącze PMOD.

## Zakres

Projekt implementuje:

- grę Guess Who na dwóch płytkach Basys 3,
- obraz VGA 1024 x 768,
- sterowanie myszą PS/2,
- komunikację UART przez PMOD,
- symulacje XSim i generowanie bitstreamu Vivado.

## Struktura katalogów

| Katalog | Zawartość |
| --- | --- |
| `rtl/` | Moduły logiki gry, renderowania, myszy, tekstu, UART i moduły wspólne |
| `fpga/` | Pliki specyficzne dla Basys 3, constraints i konfiguracja projektu Vivado |
| `sim/` | Testbenche SystemVerilog i pliki `.prj` dla symulacji |
| `tools/` | Skrypty uruchamiania symulacji, bitstreamu, programowania FPGA i raportów |
| `rtl/assets/` | Dane ROM `.dat` używane przez renderery: kursory, elementy postaci, usta, tło kart i dekoracje |
| `results/` | Bitstream oraz pomocnicze wyniki generowane przez symulacje i skrypty |

## Najważniejsze dokumenty

| Plik | Opis |
| --- | --- |
| `PROJECT_SPEC_GUESS_WHO_BASYS3.md` | Specyfikacja działania gry, stanów FSM, komunikacji i kodowania postaci |
| `RTL_MODULES_DESCRIPTION.md` | Opis modułów RTL i ich odpowiedzialności |
| `HARDWARE_SETUP.md` | Ściągawka podłączenia sprzętu, PMOD, VGA, PS/2 i przełączników |

## Przygotowanie środowiska

Komendy należy uruchamiać z katalogu głównego repozytorium. W środowisku Git
Bash należy najpierw załadować konfigurację:

```sh
. ./env.sh
```

Skrypty zakładają dostępność narzędzi Vivado/XSim w zmiennej `PATH`.

## Symulacje

Uruchomienie wszystkich testów:

```sh
run_simulation.sh -a
```

Lista dostępnych testów:

```sh
run_simulation.sh -l
```

Uruchomienie pojedynczego testu:

```sh
run_simulation.sh -t <nazwa_testu>
```

Wizualizacja wyglądu ekranu dla kolejnych stanów maszyny stanów gry:

```sh
run_simulation.sh -t fsm_state_frames
```

Test generuje pliki `results/fsm_state_000.tif` ... `fsm_state_012.tif` oraz
indeks `results/fsm_state_frames.txt`. Jest pomijany przez `run_simulation.sh -a`,
bo tworzy obrazy.

Wyniki, logi i obrazy generowane przez testy VGA trafiają do katalogu
`results/`.

## Generowanie bitstreamu

Bitstream dla Basys 3 generuje skrypt:

```sh
generate_bitstream.sh
```

Po zakończeniu skrypt kopiuje aktualny bitstream do `results/` i zapisuje
skrót ostrzeżeń w `results/warning_summary.log`. Pełne raporty syntezy,
implementacji, timingu, DRC i routingu zostają w katalogu `fpga/build/...`.

## Programowanie FPGA

Programowanie podłączonej płytki:

```sh
program_fpga.sh
```

Przed programowaniem należy upewnić się, że wybrany bitstream pochodzi z
aktualnej wersji projektu.

## Sprzęt

Podłączenie płytek, PMOD, VGA, PS/2, `SW[0]` i resetu jest opisane w
`HARDWARE_SETUP.md`.

## Czyszczenie wyników

Artefakty generowane przez narzędzia można usuwać skryptem:

```sh
clean.sh
```

Nie należy usuwać ręcznie plików źródłowych z `rtl/`, `fpga/`, `sim/`,
`rtl/assets/` ani dokumentacji projektu.
