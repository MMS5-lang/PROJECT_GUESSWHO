# Guess Who na Basys 3

## 1. Cel projektu

Celem projektu jest wykonanie sprzętowej wersji gry Guess Who na dwóch płytkach
Basys 3. Każdy gracz korzysta z osobnej płytki, osobnego monitora VGA oraz myszy
PS/2. Płytki komunikują się ze sobą przez UART wyprowadzony na złącze PMOD.

Dokument opisuje działanie gry: planszę, stany FSM, akcje gracza, pakiety UART
i kodowanie postaci.

FPGA nie analizuje rozmowy między graczami. Gracze zadają pytania słownie, tak
jak w klasycznej grze. Układ FPGA odpowiada za:

- wyświetlenie planszy z postaciami,
- wybór tajnej postaci lokalnego gracza,
- prowadzenie tur,
- lokalne eliminowanie postaci,
- zgadywanie postaci przeciwnika,
- sprawdzanie wyniku zgadywania,
- komunikację między dwiema płytkami,
- obsługę końca gry i resetu.

Najważniejsza decyzja projektowa: sekret gracza pozostaje lokalny. Płytka nie
wysyła drugiemu graczowi identyfikatora swojej tajnej postaci. Gdy przeciwnik
zgaduje, druga płytka porównuje odebrane ID z własnym `local_secret_id` i odsyła
tylko wynik: poprawny albo błędny.

## 2. Platforma sprzętowa i użyte technologie

| Obszar | Aktualna decyzja w projekcie |
| --- | --- |
| Platforma | Dwie płytki Digilent Basys 3 z układem Artix-7 |
| Język główny | SystemVerilog |
| Moduły pomocnicze | VHDL dla myszy PS/2: `MouseCtl.vhd`, `Ps2Interface.vhd` |
| Wyświetlanie | VGA 1024 x 768, zegar pikselowy 65 MHz |
| Sterowanie | Mysz PS/2 |
| Komunikacja | UART przez PMOD JA |
| Identyfikator gracza | `SW[0]`, jedna płytka ma 0, druga 1 |
| Top sprzętowy | `fpga/rtl/top_basys3.sv` |
| Top funkcjonalny gry | `rtl/top/top_vga.sv` |

Podłączenie płytek i pinów PMOD jest opisane w `HARDWARE_SETUP.md`.

## 3. Układ ekranu

Projekt używa rozdzielczości 1024 x 768. Ekran jest podzielony na dwie główne
części: planszę po lewej stronie oraz panel sterowania po prawej stronie.

Aktualna geometria z `rtl/vga/vga_pkg.sv`:

```systemverilog
HOR_PIXELS = 1024;
VER_PIXELS = 768;

BOARD_COLS = 6;
BOARD_ROWS = 3;
CELL_W     = 140;
CELL_H     = 200;
BOARD_X    = 15;
BOARD_Y    = 83;
BOARD_W    = 840;
BOARD_H    = 600;

PANEL_X    = 869;
PANEL_Y    = 170;

BUTTON_W   = 100;
BUTTON_H   = 50;
START_X    = 887;
START_Y    = 451;
RESET_X    = 887;
RESET_Y    = 524;
```

Plansza ma 6 kolumn i 3 wiersze, czyli łącznie 18 postaci. Po prawej stronie
znajduje się panel `TWOJA POSTAC`, w którym po wyborze wyświetlana jest lokalna
tajna postać gracza. Pod panelem znajdują się przyciski ekranowe:

- `START`, który po rozpoczęciu gry zmienia znaczenie na `KONIEC TURY`,
- `RESET GRY`, który działa z każdego stanu gry i przez UART prosi drugą płytkę
  o reset logiki gry.

## 4. Identyfikatory pól i postaci

Każda postać ma identyfikator liczony wierszami od lewej do prawej:

```text
character_id = row * 6 + col
```

Dla planszy 6 x 3 poprawne identyfikatory to:

| Wiersz | Kolumny | Zakres ID |
| ---: | ---: | ---: |
| 0 | 0..5 | 0..5 |
| 1 | 0..5 | 6..11 |
| 2 | 0..5 | 12..17 |

Identyfikator ma szerokość 5 bitów (`CHAR_ID_W = 5`), mimo że używane są tylko
wartości 0..17. Pozostałe wartości 18..31 są traktowane jako niepoprawne i są
odrzucane w logice gry albo w kontrolerze komunikacji.

## 5. Działanie gry krok po kroku

Ta sekcja opisuje przebieg działania projektu z punktu widzenia użytkownika.

### 5.1. Reset i oczekiwanie na link

1. Po resecie wewnętrzna maszyna gry startuje od `S_RESET`.
2. Następnie gra przechodzi do `S_WAIT_LINK`, jeżeli link z drugą płytką nie
   został jeszcze potwierdzony.
3. Kontroler komunikacji cyklicznie wysyła pakiety `HELLO`.
4. Gdy zostanie odebrany poprawny pakiet od drugiej płytki, ustawiane jest
   `link_ready`.
5. Po zestawieniu linku gra przechodzi do wyboru tajnej postaci.

Jeżeli link zostanie utracony na dłużej albo pakiety wymagające potwierdzenia
nie zostaną potwierdzone po retransmisjach, ustawiany jest `comm_error`, a gra
przechodzi do stanu `S_COMM_ERROR`.

### 5.2. Faza wyboru tajnej postaci

1. Każda płytka pokazuje planszę 6 x 3 oraz pusty panel `TWOJA POSTAC`.
2. Gracz klika lewym przyciskiem myszy na wybraną postać.
3. Kliknięta postać zostaje zapamiętana jako `selected_id`.
4. Flaga `has_secret` zostaje ustawiona.
5. Wybrana postać pojawia się w panelu po prawej stronie.
6. Podczas tej fazy gracz może zmieniać wybór dowolną liczbę razy, klikając inną
   postać.
7. W tej fazie wybrana postać na planszy jest wyróżniana magentową ramką, żeby
   zaznaczenie było dobrze widoczne na tle planszy i postaci.

W kodzie etap ten odpowiada stanowi `S_SELECT_SECRET`.

### 5.3. Zatwierdzenie wyboru przyciskiem START

1. Po wybraniu postaci gracz klika ekranowy przycisk `START`.
2. `selected_id` zostaje zapisane jako `local_secret_id`.
3. `local_ready` zostaje ustawione na 1.
4. Płytka wysyła do przeciwnika pakiet `READY`.
5. Gracz nie może już zmienić swojej tajnej postaci.
6. Wybrana postać nadal pozostaje widoczna w panelu po prawej stronie.
7. Gra czeka, aż druga płytka również wyśle `READY`.

Po kliknięciu START lokalna płytka przechodzi do `S_LOCAL_READY`. Gra rozpoczyna
się dopiero wtedy, gdy jednocześnie:

```text
local_ready  == 1
remote_ready == 1
```

### 5.4. Rozpoczęcie gry i ustalenie pierwszej tury

Po gotowości obu graczy maszyna przechodzi przez stan `S_GAME_START`.

Pierwsza tura zależy od `player_id`:

| `player_id` | Zachowanie |
| ---: | --- |
| 0 | Lokalny gracz zaczyna i przechodzi do `S_MY_TURN` |
| 1 | Lokalny gracz czeka i przechodzi do `S_OPPONENT_TURN` |

Dlatego przed uruchomieniem gry należy ustawić różne wartości `SW[0]` na dwóch
płytkach. Jeśli obie płytki mają ten sam `player_id`, logika tur nie będzie
odpowiadała poprawnej grze dwuosobowej.

### 5.5. Własna tura gracza

Stan `S_MY_TURN` oznacza, że lokalny gracz może wykonywać akcje na planszy.

Dostępne akcje:

- prawy przycisk myszy na postaci: lokalna eliminacja albo cofnięcie eliminacji,
- lewy przycisk myszy na postaci: zgadywanie tajnej postaci przeciwnika,
- kliknięcie `KONIEC TURY`: oddanie tury przeciwnikowi,
- kliknięcie `RESET GRY`: reset lokalny i wysłanie `RESET_GAME` do przeciwnika.

Przycisk START wizualnie pełni wtedy funkcję `KONIEC TURY`. Jest rysowany jako
niebieski przycisk z białym napisem.

Pod panelem wyświetlane są krótkie podpowiedzi sterowania: `LPM ZGADNIJ` oraz
`PPM ELIMINUJ`. Nie ma już dodatkowej linii `START KONIEC`, bo znaczenie
przycisku wynika z napisu na samym przycisku.

### 5.6. Lokalna eliminacja postaci

Podczas własnej tury gracz może kliknąć prawym przyciskiem myszy na dowolną
postać. W obecnym kodzie eliminacja działa jako przełącznik:

```systemverilog
eliminated_mask_nxt = eliminated_mask ^ char_mask;
```

Oznacza to, że:

- pierwsze kliknięcie PPM eliminuje postać,
- drugie kliknięcie PPM na tej samej postaci cofa eliminację.

Eliminacje są lokalne. Nie są wysyłane do drugiej płytki, ponieważ każdy gracz
prowadzi własną dedukcję na podstawie rozmowy.

Wyeliminowana postać jest przygaszana żółtawą nakładką i ma na środku żółty znak
zapytania. Efekt jest tylko wizualny; sama informacja o eliminacji dalej jest
przechowywana jako bit w `eliminated_mask`.

Po każdej eliminacji logika sprawdza, czy na planszy został co najmniej jeden
aktywny kandydat. Próba wykreślenia ostatniej niewyeliminowanej postaci jest
ignorowana, żeby gracz nie mógł przypadkowo doprowadzić maski eliminacji do
stanu pustej planszy.

Wykreślenie 17 postaci nie wykonuje już automatycznego strzału w ostatnią
postać. Lokalna gra zostaje w `S_MY_TURN`; gracz może ręcznie kliknąć LPM na
ostatniej postaci, żeby wysłać zwykły `GUESS`, albo kliknąć `KONIEC TURY`, żeby
oddać ruch przeciwnikowi.

### 5.7. Zgadywanie postaci przeciwnika

Podczas własnej tury lewy przycisk myszy na postaci oznacza natychmiastowe
zgadywanie. Nie ma dodatkowego potwierdzenia.

Przebieg:

1. Gracz klika LPM na postaci.
2. Lokalna płytka zapisuje ID jako `last_guess_id`.
3. Lokalna płytka wysyła `GUESS(character_id)` do drugiej płytki.
4. Lokalna gra przechodzi do `S_WAIT_GUESS_RESULT`.
5. Druga płytka porównuje odebrane ID ze swoim `local_secret_id`.
6. Druga płytka odsyła `RESULT_CORRECT(character_id)` albo
   `RESULT_WRONG(character_id)`.

Jeśli wynik jest poprawny:

- zgadujący gracz przechodzi do `S_WIN`,
- przeciwnik przechodzi do `S_LOSE`,
- na ekranie pojawia się komunikat `WYGRALES` albo `PRZEGRALES`.

Jeśli wynik jest błędny:

- zgadujący gracz przechodzi do `S_WRONG_GUESS_FEEDBACK`,
- błędnie wskazana postać zostaje dopisana do lokalnej maski eliminacji,
- błędnie wskazana postać jest oznaczona czerwoną ramką,
- komunikat `NIEPOPRAWNA POSTAC` jest widoczny przez około 3 sekundy,
- po czasie feedbacku zgadująca płytka wysyła `TURN_END` i przechodzi do
  `S_OPPONENT_TURN`,
- druga płytka przechodzi do `S_MY_TURN` dopiero po odebraniu tego `TURN_END`.

W kodzie czas komunikatu jest ustawiony jako:

```systemverilog
FEEDBACK_FRAMES = 180;
```

Przy 60 klatkach na sekundę odpowiada to około 3 sekundom.

### 5.8. Ostatnia niewyeliminowana postać

Jeżeli po lokalnych eliminacjach zostaje dokładnie jedna aktywna postać,
`game_core` nie traktuje jej już jako automatycznego strzału.

Przebieg:

1. Aktywny gracz eliminuje postacie PPM.
2. Po eliminacji logika aktualizuje `eliminated_mask`, o ile zostaje co najmniej
   jedna aktywna postać.
3. Jeżeli została jedna postać, gra pozostaje w `S_MY_TURN`.
4. Płytka nie wysyła `FINAL_CHECK` i nie zmienia `last_guess_id`.
5. Gracz może kliknąć LPM na dowolnej postaci, w tym na ostatniej aktywnej, żeby
   wysłać zwykły `GUESS(character_id)`.
6. Gracz może też kliknąć `KONIEC TURY`, aby oddać ruch przeciwnikowi.

Dzięki temu samo wykreślenie 17 postaci nie kończy gry i nie odbiera drugiemu
graczowi możliwości wykonania jeszcze jednego ruchu.

### 5.9. Tura przeciwnika

Stan `S_OPPONENT_TURN` oznacza, że lokalny gracz czeka na ruch drugiej płytki.

W tym stanie:

- kliknięcia eliminacji i zgadywania nie zmieniają lokalnej gry,
- na ekranie widoczny jest komunikat `TURA RYWALA / ODPOWIEDZ / NA PYTANIE`,
- kursor zmienia się w klepsydrę,
- lokalna płytka może odebrać `GUESS`, `FINAL_CHECK`, `TURN_END` albo
  `RESET_GAME`.

Jeżeli przeciwnik wyśle `GUESS` albo `FINAL_CHECK`, lokalna płytka porównuje ID
z `local_secret_id` i odsyła odpowiedni wynik. Po błędnym `GUESS` lokalna płytka
nadal zostaje w `S_OPPONENT_TURN`, aby przeciwnik zdążył wyświetlić komunikat
`NIEPOPRAWNA POSTAC`. Do `S_MY_TURN` przechodzi dopiero po odebraniu `TURN_END`.

### 5.10. Reset gry

Ekranowy `RESET GRY` działa z każdego stanu. Lokalnie czyści stan gry i stan
komunikacji, a do drugiej płytki wysyła `RESET_GAME`.

Odebrany `RESET_GAME` czyści stan gry i komunikacji po stronie odbiornika.
Pakiet jest idempotentny, więc retransmisja resetu może ponownie wyczyścić stan.

`BTNC` jest lokalnym resetem sprzętowym. Nie wysyła `RESET_GAME`. Szczegóły
użycia `BTNC` są w `HARDWARE_SETUP.md`.

### 5.11. Błąd komunikacji

Projekt ma obsługę błędu komunikacji. `pmod_comm_controller` ustawia
`comm_error`, gdy:

- po zestawieniu linku przez długi czas nie ma poprawnych pakietów,
- pakiet wymagający ACK nie zostanie potwierdzony mimo ponowień.

Po takim błędzie `game_core` przechodzi do `S_COMM_ERROR`. Na ekranie pojawia
się komunikat `ERROR NA LINK`. Kliknięcie ekranowego `RESET GRY` wysyła
`RESET_GAME`, czyści lokalny stan komunikacji i wraca do ponownego szukania
linku.

Jeżeli płytki nie są fizycznie połączone przez UART, link nie zostanie
zestawiony i gra zostanie w `S_WAIT_LINK`. Jeżeli link był już zestawiony, a
połączenie zostanie przerwane, kontroler po czasie bez poprawnych pakietów
ustawi `comm_error`.

## 6. Sterowanie myszą i kursory

Projekt używa myszy PS/2 jako głównego interfejsu użytkownika.

| Akcja | Znaczenie |
| --- | --- |
| LPM na postaci w `S_SELECT_SECRET` | Wybór tajnej postaci |
| LPM na postaci w `S_MY_TURN` | Zgadywanie postaci przeciwnika |
| PPM na postaci w `S_MY_TURN` | Przełączenie eliminacji lokalnej |
| LPM na `START` | Zatwierdzenie tajnej postaci |
| LPM na `KONIEC TURY` | Oddanie tury przeciwnikowi |
| LPM na `RESET GRY` | Reset lokalny i wysłanie `RESET_GAME` do drugiej płytki |

Kursory:

| Tryb | Kiedy występuje |
| --- | --- |
| `CURSOR_POINTER` | Kursor poza aktywnymi hitboxami |
| `CURSOR_POINTER_HOVER` | Kursor nad planszą lub przyciskami |
| `CURSOR_BUSY` | Tura przeciwnika, czyli `S_OPPONENT_TURN` |

## 7. Stany maszyny gry

Aktualna maszyna stanów jest zdefiniowana w `rtl/game/guess_who_pkg.sv` jako
`game_state_t`.

| Stan | Kod | Znaczenie w obecnym projekcie |
| --- | ---: | --- |
| `S_RESET` | 0 | Stan po asynchronicznym resecie rejestrów gry |
| `S_WAIT_LINK` | 1 | Oczekiwanie na poprawny link z drugą płytką |
| `S_SELECT_SECRET` | 2 | Wybór lokalnej tajnej postaci przez LPM |
| `S_LOCAL_READY` | 3 | Lokalny gracz kliknął START i czeka na gotowość przeciwnika |
| `S_GAME_START` | 4 | Stan przejściowy ustalający pierwszą turę na podstawie `player_id` |
| `S_MY_TURN` | 5 | Lokalny gracz może eliminować, zgadywać lub zakończyć turę |
| `S_OPPONENT_TURN` | 6 | Lokalny gracz czeka na ruch przeciwnika |
| `S_WAIT_GUESS_RESULT` | 7 | Po wysłaniu `GUESS` oczekiwany jest wynik od przeciwnika |
| `S_WRONG_GUESS_FEEDBACK` | 8 | Błędny strzał jest pokazywany przez około 3 sekundy |
| `S_FINAL_CHECK` | 9 | Oczekiwanie na wynik `FINAL_CHECK`; lokalna eliminacja PPM nie wchodzi już do tego stanu |
| `S_WIN` | 10 | Lokalny gracz wygrał |
| `S_LOSE` | 11 | Lokalny gracz przegrał |
| `S_COMM_ERROR` | 12 | Błąd komunikacji albo utrata linku |

Najważniejsze przejścia:

| Z bieżącego stanu | Warunek | Następny stan |
| --- | --- | --- |
| `S_RESET` | `link_ready == 1` | `S_SELECT_SECRET` |
| `S_RESET` | `link_ready == 0` | `S_WAIT_LINK` |
| `S_WAIT_LINK` | `link_ready == 1` | `S_SELECT_SECRET` |
| `S_SELECT_SECRET` | `START` i wybrana postać | `S_LOCAL_READY` |
| `S_LOCAL_READY` | `local_ready && remote_ready` | `S_GAME_START` |
| `S_GAME_START` | `player_id == 0` | `S_MY_TURN` |
| `S_GAME_START` | `player_id == 1` | `S_OPPONENT_TURN` |
| `S_MY_TURN` | LPM na postaci | `S_WAIT_GUESS_RESULT` |
| `S_MY_TURN` | PPM na postaci i co najmniej jedna aktywna postać zostaje | `S_MY_TURN` |
| `S_MY_TURN` | `KONIEC TURY` | `S_OPPONENT_TURN` |
| `S_WAIT_GUESS_RESULT` | wynik poprawny | `S_WIN` |
| `S_WAIT_GUESS_RESULT` | wynik błędny | `S_WRONG_GUESS_FEEDBACK` |
| `S_WAIT_GUESS_RESULT` | brak wyniku przez 600 ramek | `S_COMM_ERROR` |
| `S_WRONG_GUESS_FEEDBACK` | minęło 180 ramek; wysyłane jest `TURN_END` | `S_OPPONENT_TURN` |
| `S_FINAL_CHECK` | wynik poprawny | `S_WIN` |
| `S_FINAL_CHECK` | wynik błędny | `S_LOSE` |
| `S_FINAL_CHECK` | brak wyniku przez 600 ramek | `S_COMM_ERROR` |
| `S_OPPONENT_TURN` | błędny `GUESS` przeciwnika | `S_OPPONENT_TURN` |
| `S_OPPONENT_TURN` | `TURN_END` od przeciwnika | `S_MY_TURN` |
| dowolny stan | kliknięcie `RESET GRY` albo odebranie `RESET_GAME` | `S_WAIT_LINK` |
| dowolny stan | `comm_error` | `S_COMM_ERROR` |

## 8. Dane przechowywane przez logikę gry

Najważniejsze rejestry i sygnały stanu w `game_core.sv`:

| Sygnał | Znaczenie |
| --- | --- |
| `state` | Aktualny stan FSM gry |
| `eliminated_mask[17:0]` | Lokalna maska eliminacji; 1 oznacza postać wyeliminowaną |
| `selected_id[4:0]` | Aktualnie kliknięta postać przed zatwierdzeniem START |
| `local_secret_id[4:0]` | Zatwierdzona tajna postać lokalnego gracza |
| `last_guess_id[4:0]` | Ostatnio zgadywana postać |
| `has_secret` | Informacja, że lokalny gracz wybrał postać |
| `local_ready` | Lokalny gracz zatwierdził wybór |
| `remote_ready` | Przeciwnik zatwierdził wybór |
| `feedback_cnt` | Licznik ramek dla komunikatu błędnej postaci |
| `result_wait_cnt` | Licznik ramek oczekiwania na wynik `GUESS` albo `FINAL_CHECK` |

Maska eliminacji jest lokalna i nie jest synchronizowana z drugą płytką.

## 9. Komunikacja między płytkami

Komunikacja jest realizowana przez `pmod_comm_controller.sv`, który korzysta z
`uart_byte_link.sv` i rdzenia UART z katalogu `rtl/comm/uart`.

Aktualny format pakietu ma 6 bajtów:

| Bajt | Pole | Znaczenie |
| ---: | --- | --- |
| 0 | `START_BYTE` | Stała `8'hA5` |
| 1 | `packet_type` | Typ pakietu, dolne 4 bity |
| 2 | `player_id` | ID nadawcy, używany bit 0 |
| 3 | `payload` | Dane pakietu, np. ID postaci |
| 4 | `sequence_number` | Numer sekwencyjny pakietu |
| 5 | `checksum` | XOR pól pakietu |

Pakiet jest akceptowany tylko wtedy, gdy:

- bajt startowy jest poprawny,
- checksum jest poprawny,
- górne 4 bity bajtu typu są równe 0,
- typ pakietu jest wspierany,
- górne 7 bitów bajtu `player_id` jest równe 0,
- `player_id` nie jest równy lokalnemu `player_id`,
- payload jest poprawny dla danego typu pakietu,
- `PKT_ACK` potwierdza istniejący typ pakietu.

Typy pakietów:

| Typ | Kod | Payload | Znaczenie |
| --- | ---: | --- | --- |
| `PKT_HELLO` | 0 | 0 | Okresowe potwierdzenie obecności drugiej płytki |
| `PKT_READY` | 2 | 0 | Gracz zatwierdził swoją postać |
| `PKT_TURN_END` | 3 | 0 | Aktywny gracz kończy turę |
| `PKT_GUESS` | 4 | `character_id` | Gracz zgaduje postać przeciwnika |
| `PKT_FINAL_CHECK` | 5 | `character_id` | Sprawdzenie jedynej pozostałej postaci |
| `PKT_RESULT_CORRECT` | 6 | `character_id` | Wynik poprawny |
| `PKT_RESULT_WRONG` | 7 | `character_id` | Wynik błędny |
| `PKT_RESET_GAME` | 8 | 0 | Żądanie resetu gry po stronie odbiornika |
| `PKT_ACK` | 9 | typ potwierdzanego pakietu | Potwierdzenie pakietu wymagającego ACK |

Pakiety `READY`, `TURN_END`, `GUESS`, `FINAL_CHECK`, `RESULT_CORRECT`,
`RESULT_WRONG` i `RESET_GAME` wymagają potwierdzenia ACK. Jeżeli ACK nie wróci w
zadanym czasie, pakiet jest wysyłany ponownie z tym samym numerem sekwencyjnym.
Odbiornik potwierdza duplikaty, ale nie generuje drugi raz tego samego zdarzenia
gry. Wyjątkiem jest `RESET_GAME`, który jest idempotentny i może ponownie
wyczyścić stan gry oraz komunikacji, jeśli przychodzi jako retransmisja po
błędzie linku.

Aktualne parametry ochrony komunikacji:

| Parametr | Wartość w RTL | Znaczenie |
| --- | ---: | --- |
| `BAUD_RATE` | 115200 | Prędkość UART |
| `HELLO_INTERVAL_CYCLES` | 1 000 000 | Okres wysyłania `HELLO`, około 15,4 ms przy 65 MHz |
| `ACK_TIMEOUT_CYCLES` | `CLK_FREQ_HZ / 4` | Oczekiwanie na ACK, około 250 ms |
| `MAX_RETRIES` | 3 | Maksymalna liczba ponowień pakietu wymagającego ACK |
| `COMM_TIMEOUT_CYCLES` | `CLK_FREQ_HZ * 5` | Timeout braku poprawnych pakietów po zestawieniu linku, około 5 s |

Kontroler ignoruje pakiety z niepoprawnym ID postaci, z własnym `player_id`,
nieznanym typem, błędnym checksumem albo złym bajtem startowym. Wyniki
`RESULT_CORRECT` i `RESULT_WRONG` są przyjmowane tylko wtedy, gdy payload zgadza
się z aktualnie oczekiwanym ID po wysłaniu `GUESS` albo `FINAL_CHECK`.

## 10. Kodowanie postaci

Postacie nie są przechowywane jako 18 pełnych, niezależnych obrazów. Projekt
używa podejścia cechowego: każda postać ma 12-bitowy wektor cech w
`face_traits_rom.sv`, a `face_renderer.sv` na tej podstawie dobiera odpowiednie
bitmapy i kolory.

Aktualne znaczenie bitów `traits[11:0]`:

| Bit | Nazwa cechy | Wpływ na renderowanie |
| ---: | --- | --- |
| 11 | Broda | Włącza warstwę brody |
| 10 | Czapka z daszkiem | Włącza warstwę czapki |
| 9 | Kapelusz | Włącza warstwę kapelusza |
| 8 | Zwykłe okulary | Włącza warstwę okularów |
| 7 | Włosy 2 | Włącza drugi wariant włosów |
| 6 | Włosy 1 | Włącza pierwszy wariant włosów |
| 5 | Kolor włosów | Wybiera blond albo ciemne włosy |
| 4 | Kolor oczu | Wybiera wariant koloru oczu |
| 3 | Kolor skóry | Wybiera wariant koloru skóry |
| 2 | Okulary przeciwsłoneczne | Włącza warstwę okularów przeciwsłonecznych |
| 1 | Kolor czapki | Wybiera wariant koloru czapki |
| 0 | Pejsy | Włącza warstwę pejsów |

Aktualne wpisy ROM dla postaci:

| ID | `traits[11:0]` |
| ---: | --- |
| 0 | `1000_1000_1000` |
| 1 | `0100_0101_1100` |
| 2 | `0010_1000_0000` |
| 3 | `1011_1000_0001` |
| 4 | `0000_1011_1100` |
| 5 | `0001_1010_0000` |
| 6 | `1100_0011_0010` |
| 7 | `1010_0101_1100` |
| 8 | `0000_1000_0000` |
| 9 | `0000_0110_1000` |
| 10 | `0100_1000_0000` |
| 11 | `0001_0100_1010` |
| 12 | `1011_1011_1001` |
| 13 | `1000_0101_0000` |
| 14 | `0100_1000_1111` |
| 15 | `0000_1001_1000` |
| 16 | `0000_0110_0100` |
| 17 | `1001_0001_0000` |

Taki sposób kodowania oszczędza pamięć i pozwala tworzyć wiele postaci przez
kombinowanie tych samych elementów graficznych.

## 11. Stany ekranowe i informacja dla gracza

Projekt informuje gracza o stanie gry na dwa sposoby:

- przez napisy w panelu bocznym,
- przez zmianę kursora.

Przykłady komunikatów ekranowych:

| Stan | Komunikat |
| --- | --- |
| `S_WAIT_LINK` | `CZEKAM / NA LINK` |
| `S_SELECT_SECRET` | `WYBIERZ / SWOJA / POSTAC` |
| `S_LOCAL_READY` | `TY GOTOWY` albo `POCZEKAJ` oraz `RYWAL CZEKA` albo `RYWAL GOTOWY` |
| `S_MY_TURN` | `TWOJA TURA / ZADAJ / PYTANIE` |
| `S_OPPONENT_TURN` | `TURA RYWALA / ODPOWIEDZ / NA PYTANIE` |
| `S_WAIT_GUESS_RESULT` | `CZEKAM / NA WYNIK` |
| `S_FINAL_CHECK` | `OSTATNIA / POSTAC / SPRAWDZAM` |
| `S_WRONG_GUESS_FEEDBACK` | `NIEPOPRAWNA / POSTAC` |
| `S_WIN` | `WYGRALES` |
| `S_LOSE` | `PRZEGRALES` |
| `S_COMM_ERROR` | `ERROR / NA LINK` |

Tura przeciwnika jest sygnalizowana zarówno tekstem ekranowym, jak i klepsydrą
(`CURSOR_BUSY`).
