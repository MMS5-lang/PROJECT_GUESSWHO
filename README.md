# PROJECT_GUESSWHO

Repozytorium zawiera implementację gry Guess Who dla dwóch płytek Digilent
Basys 3. Każda płytka obsługuje własny ekran VGA, mysz PS/2 i komunikuje się z
drugą płytką przez UART wyprowadzony na złącze PMOD.

## Cel projektu

Celem projektu jest sprzętowa implementacja rozgrywki dwuosobowej:

- wybór tajnej postaci przez każdego gracza,
- prowadzenie tur,
- lokalna eliminacja postaci,
- zgadywanie postaci przeciwnika,
- wymiana zdarzeń między płytkami przez UART,
- wyświetlanie planszy, panelu gracza, przycisków, komunikatów i kursora na VGA.

## Struktura katalogów

| Katalog | Zawartość |
| --- | --- |
| `rtl/` | Moduły logiki gry, renderowania, myszy, tekstu, UART i moduły wspólne |
| `fpga/` | Pliki specyficzne dla Basys 3, constraints i konfiguracja projektu Vivado |
| `sim/` | Testbenche SystemVerilog i pliki `.prj` dla symulacji |
| `tools/` | Skrypty uruchamiania symulacji, bitstreamu, programowania FPGA i raportów |
| `rtl/assets/` | Dane ROM używane przez renderery, między innymi kursory, elementy postaci i tło kart |
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

Ten test generuje po jednej klatce `.tif` dla każdego stanu FSM w katalogu
`results/`, jako pliki `fsm_state_000.tif` ... `fsm_state_013.tif`. Plik
`results/fsm_state_frames.txt` opisuje, który numer klatki odpowiada któremu
stanowi. Klatki przechodzą przez pełny tor renderowania, więc widać na nich tło,
ramki, postacie, teksty i kursor. Test jest uruchamiany ręcznie i jest pomijany
przez `run_simulation.sh -a`, żeby standardowy zestaw symulacji nie generował
dużych obrazów przy każdym uruchomieniu.

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

Minimalny zestaw uruchomieniowy:

- dwie płytki Basys 3,
- dwa monitory VGA albo jeden monitor używany naprzemiennie,
- dwie myszy PS/2,
- przewody do połączenia UART między PMOD-ami,
- wspólna masa między płytkami.

Szczegółowe przypisanie linii znajduje się w `HARDWARE_SETUP.md`.

## Czyszczenie wyników

Artefakty generowane przez narzędzia można usuwać skryptem:

```sh
clean.sh
```

Nie należy usuwać ręcznie plików źródłowych z `rtl/`, `fpga/`, `sim/`,
`rtl/assets/` ani dokumentacji projektu.
