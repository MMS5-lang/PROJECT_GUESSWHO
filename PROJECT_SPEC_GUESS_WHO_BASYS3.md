# Specyfikacja projektu: FPGA „Zgadnij kto?” na Basys 3

Ten plik jest roboczą specyfikacją projektu do trzymania w repozytorium. Ma być czytelny zarówno dla osoby piszącej kod, jak i dla asystenta typu Codex. Traktuj go jako źródło prawdy dla architektury, logiki gry, renderowania i komunikacji między dwiema płytkami.

## 1. Cel projektu

Projekt jest sprzętową wersją gry „Zgadnij kto?” uruchamianą na **dwóch płytkach Digilent Basys 3** z układami Artix-7. Każdy gracz ma własną płytkę, własny ekran VGA i własną mysz PS/2. Gracze rozmawiają ze sobą normalnie głosowo, a FPGA obsługuje planszę, wybór tajnej postaci, eliminowanie postaci, tury, zgadywanie, komunikację między płytkami i wynik gry.

Najważniejsze założenie interfejsu: ekran zawiera **planszę 6 × 3 po lewej stronie**, czyli łącznie **18 postaci**, oraz **panel po prawej stronie pokazujący wybraną tajną twarz lokalnego gracza**.

## 2. Platforma i technologie

| Obszar | Decyzja projektowa |
|---|---|
| Platforma | 2 × Digilent Basys 3 / Artix-7 |
| Język RTL | SystemVerilog jako główny język projektu |
| Dopuszczalne moduły pomocnicze | Istniejące moduły VHDL do PS/2, jeżeli są poprawnie opakowane/adaptowane |
| Wyświetlanie | VGA, preferowane 1024 × 768 albo rozdzielczość bardzo zbliżona |
| Sterowanie | Mysz PS/2 jako główny interfejs użytkownika |
| Komunikacja | Prosty link cyfrowy między płytkami, np. PMOD albo UART-like |
| Reset | Reset asynchroniczny dla logiki gry i rejestrów sterujących |
| Styl projektu | `top` głównie strukturalny, logika podzielona na osobne moduły |

## 3. Najważniejsza zmiana względem pierwotnej specyfikacji

Pierwotna koncepcja zakładała planszę **5 × 4**. W tym projekcie używamy planszy:

```text
BOARD_COLS    = 6
BOARD_ROWS    = 3
N_CHARACTERS  = 18
```

Identyfikator postaci jest liczony wierszami od lewej do prawej:

```systemverilog
character_id = row * BOARD_COLS + col;
```

Dla planszy 6 × 3 poprawne identyfikatory to `0..17`.

## 4. Układ ekranu

Ekran ma być podzielony na trzy główne części:

1. **Plansza po lewej stronie**: siatka 6 kolumn × 3 wiersze. Każde pole zawiera jedną twarz/postać.
2. **Panel wybranej postaci po prawej stronie**: miejsce na kopię lokalnej tajnej postaci gracza. Panel nie pokazuje sekretu przeciwnika.
3. **Przyciski ekranowe na dole**: `START` / `KONIEC TURY` oraz `RESET GRY`.

Przykładowy układ dla VGA 1024 × 768:

```systemverilog
localparam int SCREEN_W = 1024;
localparam int SCREEN_H = 768;

localparam int BOARD_X  = 32;
localparam int BOARD_Y  = 32;
localparam int BOARD_W  = 720;
localparam int BOARD_H  = 540;
localparam int CELL_W   = BOARD_W / 6;   // 120
localparam int CELL_H   = BOARD_H / 3;   // 180

localparam int SELECTED_FACE_PANEL_X = 820;
localparam int SELECTED_FACE_PANEL_Y = 100;
localparam int SELECTED_FACE_PANEL_W = 150;
localparam int SELECTED_FACE_PANEL_H = 200;

localparam int BUTTON_Y = 700;
```

Współrzędne można dostroić do finalnego renderera, ale **relacja układu ma pozostać taka sama**: duża plansza 6 × 3 po lewej, panel wybranej twarzy po prawej, przyciski na dole.

## 5. Kolory i znaczenie ramek

| Element | Znaczenie |
|---|---|
| Czarna ramka zewnętrzna | Obramowanie całej planszy |
| Szare ramki pól | Domyślny stan pól postaci |
| Niebieska ramka | Postać wybrana przed kliknięciem `START`, jeszcze niezatwierdzona |
| Zielona ramka | Poprawny strzał albo poprawna ostatnia pozostała postać |
| Czerwona ramka | Błędny strzał albo błędna ostatnia pozostała postać |
| Szare zakrycie pola | Postać lokalnie wyeliminowana przez gracza |

Panel po prawej stronie pokazuje lokalnie wybraną tajną postać. Po kliknięciu `START` ta postać pozostaje widoczna w panelu, ale na głównej planszy ramka wraca do stanu normalnego.

## 6. Sterowanie myszą

### Przed startem gry

| Akcja | Efekt |
|---|---|
| LPM na postaci | Wybór tymczasowej tajnej postaci, ustawienie `provisional_secret_id` |
| LPM na innej postaci | Zmiana wyboru tymczasowego |
| Kliknięcie `START` | Zatwierdzenie tajnej postaci, zapis do `local_secret_id`, wysłanie `READY` do drugiej płytki |
| Kliknięcie `RESET GRY` | Reset lokalnej rozgrywki i wysłanie `RESET_GAME` |

### Po starcie gry

| Akcja | Warunek | Efekt |
|---|---|---|
| PPM na postaci | Tylko podczas własnej tury | Eliminacja lokalna postaci albo przełączenie eliminacji, zależnie od wariantu implementacji |
| LPM na postaci | Tylko podczas własnej tury | Natychmiastowe zgadywanie postaci przeciwnika przez wysłanie `GUESS(character_id)` |
| Kliknięcie `KONIEC TURY` | Tylko podczas własnej tury | Wysłanie `TURN_END` i oddanie tury przeciwnikowi |
| Kliknięcie `RESET GRY` | W dowolnym stanie | Wysłanie `RESET_GAME` i powrót obu płytek do wyboru postaci |

Rekomendacja: w wersji docelowej PPM może działać jako **toggle eliminacji**, czyli pierwsze kliknięcie eliminuje postać, a drugie ją przywraca. W wersji MVP można najpierw zrobić prostszy wariant: PPM tylko ustawia bit eliminacji.

## 7. Przebieg gry

### 7.1. Reset i wybór postaci

Po resecie gra przechodzi do fazy wyboru tajnej postaci. Obie płytki pokazują planszę 6 × 3 oraz pusty panel wybranej postaci po prawej stronie. Gracz klika LPM na wybranej twarzy. Wybrane pole dostaje niebieską ramkę, a ta sama twarz pojawia się w panelu po prawej.

Wybór można zmieniać dowolnie aż do kliknięcia `START`.

### 7.2. Zatwierdzenie `START`

Po kliknięciu `START`:

1. `provisional_secret_id` zostaje zapisany jako `local_secret_id`.
2. `local_ready` zostaje ustawione na `1`.
3. Zmiana tajnej postaci zostaje zablokowana.
4. Na głównej planszy niebieska ramka znika, a ramki wracają do koloru domyślnego.
5. Wybrana twarz nadal jest widoczna w panelu po prawej.
6. Płytka wysyła do drugiej płytki pakiet `READY`.
7. Gra zaczyna się dopiero wtedy, gdy `local_ready == 1` oraz `remote_ready == 1`.

Sekret gracza **nie powinien być wysyłany do drugiej płytki na początku gry**. Każda płytka zna tylko własną tajną postać. Gdy przeciwnik zgaduje, druga płytka sprawdza ID lokalnie i odsyła jedynie wynik: poprawny albo błędny.

### 7.3. Tury

Po starcie gry tylko gracz mający turę może eliminować i zgadywać postacie. Gracz bez tury nadal widzi planszę, ale kliknięcia eliminacji i zgadywania są ignorowane.

Początkową turę można ustalić za pomocą `PLAYER_ID`, np. z przełącznika `SW[0]`:

```text
PLAYER_ID = 0 -> zaczyna gracz 0
PLAYER_ID = 1 -> czeka na ruch gracza 0
```

W praktyce obie płytki powinny mieć różne wartości `PLAYER_ID`.

### 7.4. Eliminacja postaci

Eliminacje są lokalne. Nie synchronizujemy ich między płytkami, ponieważ każdy gracz prowadzi własną dedukcję na podstawie rozmowy.

Dane eliminacji:

```systemverilog
logic [17:0] eliminated_mask; // 1 = postać lokalnie wyeliminowana
```

Po eliminacji renderer powinien zakryć środek pola szarym kolorem, ale nadal może zostawić widoczną ramkę pola.

Po każdej eliminacji należy sprawdzić, czy została dokładnie jedna niewyeliminowana postać. Jeżeli tak, wykonywany jest automatyczny `FINAL_CHECK`.

### 7.5. Zgadywanie LPM

Podczas własnej tury LPM na postaci oznacza natychmiastowy strzał. Nie ma osobnego potwierdzenia.

Przebieg:

1. Aktywna płytka wysyła `GUESS(character_id)` do przeciwnika.
2. Płytka przeciwnika porównuje `character_id` ze swoim `local_secret_id`.
3. Jeżeli ID się zgadza, przeciwnik odsyła `RESULT_CORRECT(character_id)`.
4. Jeżeli ID się nie zgadza, przeciwnik odsyła `RESULT_WRONG(character_id)`.

Wynik poprawny:

- gracz zgadujący widzi zieloną ramkę na trafionej postaci,
- pojawia się komunikat `WYGRALES`,
- gra przechodzi do stanu końcowego,
- przeciwnik widzi komunikat `PRZEGRALES`.

Wynik błędny:

- gracz zgadujący widzi czerwoną ramkę na błędnej postaci przez około 3 sekundy,
- po czasie feedbacku postać zostaje lokalnie wyeliminowana,
- tura przechodzi do przeciwnika.

### 7.6. Koniec gry przez pozostawienie jednej postaci

Jeżeli po eliminacji została dokładnie jedna aktywna postać, gra traktuje ją jako finalny wybór gracza:

1. Aktywna płytka znajduje `remaining_character_id`.
2. Wysyła `FINAL_CHECK(remaining_character_id)`.
3. Przeciwnik porównuje ID ze swoim `local_secret_id`.
4. Wynik jest taki sam jak przy zwykłym zgadywaniu:
   - poprawny wynik: aktywny gracz wygrywa,
   - błędny wynik: aktywny gracz przegrywa.

### 7.7. Reset gry

`RESET GRY` działa w każdym stanie. Kliknięcie resetu:

- wysyła `RESET_GAME` do drugiej płytki,
- czyści gotowość graczy,
- czyści sekrety i wybór tymczasowy,
- czyści `eliminated_mask`,
- czyści ostatni strzał,
- resetuje tury,
- usuwa komunikaty zwycięstwa/przegranej,
- wraca do fazy wyboru postaci.

Jest to reset logiki gry. Nie musi resetować całego FPGA ani modułów PLL/clock wizard.

## 8. Dane przechowywane w `game_core`

Przykładowy zestaw rejestrów:

```systemverilog
logic [4:0] provisional_secret_id;     // kliknięta postać przed START, 0..17
logic       provisional_secret_valid;

logic [4:0] local_secret_id;           // zatwierdzona własna tajna postać, 0..17
logic       local_ready;
logic       remote_ready;

logic [17:0] eliminated_mask;           // 1 = postać lokalnie wyeliminowana

logic [4:0] last_guess_id;
logic [4:0] last_wrong_guess_id;
logic [4:0] last_correct_guess_id;
logic       last_guess_valid;

logic       my_turn;
logic       player_id;

logic [8:0] feedback_timer_frames;      // np. ok. 3 sekundy przy zliczaniu frame_tick
logic       win_flag;
logic       lose_flag;
```

Mimo że jest tylko 18 postaci, ID może mieć 5 bitów, bo ułatwia to format pakietów i porównania. Wszędzie trzeba jednak sprawdzać, że ID jest mniejsze od `N_CHARACTERS`.

## 9. Mapowanie kliknięć na pola

`hitbox_decoder` powinien zamieniać współrzędne myszy na typ klikniętego elementu:

- pole postaci `0..17`,
- przycisk `START` / `KONIEC TURY`,
- przycisk `RESET GRY`,
- panel wybranej postaci albo tło, jeżeli kliknięcie nie ma znaczenia.

Dla planszy:

```text
row = 0..2
col = 0..5
character_id = row * 6 + col
```

W RTL najlepiej unikać dzielenia przez zmienne. Ponieważ pola mają stały rozmiar, `hitbox_decoder` może być napisany jako zestaw porównań zakresów, np. `mouse_x >= CELL0_X0 && mouse_x < CELL0_X1`.

## 10. Proponowana maszyna stanów gry

| Stan | Znaczenie |
|---|---|
| `S_RESET` | Asynchroniczny reset rejestrów gry |
| `S_WAIT_LINK` | Oczekiwanie na komunikację z drugą płytką |
| `S_SELECT_SECRET` | Wybór własnej tajnej postaci LPM |
| `S_LOCAL_READY` | `START` kliknięty lokalnie, czekamy na `READY` przeciwnika |
| `S_GAME_START` | Obie płytki gotowe, ustalenie pierwszej tury |
| `S_MY_TURN` | Lokalny gracz może eliminować, zgadywać albo zakończyć turę |
| `S_OPPONENT_TURN` | Lokalny gracz czeka; kliknięcia planszy są ignorowane |
| `S_WAIT_GUESS_RESULT` | Po wysłaniu `GUESS` albo `FINAL_CHECK` czekamy na wynik |
| `S_WRONG_GUESS_FEEDBACK` | Czerwona ramka błędnego strzału przez ok. 3 sekundy |
| `S_WIN` | Komunikat `WYGRALES`, zielona ramka, koniec gry |
| `S_LOSE` | Komunikat `PRZEGRALES`, koniec gry |
| `S_GAME_OVER` | Stan końcowy do kliknięcia `RESET GRY` |
| `S_COMM_ERROR` | Błąd albo utrata komunikacji z drugą płytką |

## 11. Komunikacja między płytkami

Komunikacja jest potrzebna do synchronizacji gotowości, tur, zgadywania, wyników i resetu. Nie trzeba synchronizować `eliminated_mask`.

Minimalne typy pakietów:

| Pakiet | Payload | Znaczenie |
|---|---:|---|
| `HELLO` / `HEARTBEAT` | opcjonalnie `player_id` | Sprawdzenie, czy druga płytka jest podłączona |
| `READY` | brak | Gracz zatwierdził swoją postać |
| `TURN_END` | brak | Aktywny gracz kończy turę |
| `GUESS` | `character_id`, 0..17 | Gracz zgaduje postać przeciwnika |
| `FINAL_CHECK` | `character_id`, 0..17 | Sprawdzenie jedynej pozostałej postaci |
| `RESULT_CORRECT` | `character_id`, 0..17 | Strzał/finalny wybór jest poprawny |
| `RESULT_WRONG` | `character_id`, 0..17 | Strzał/finalny wybór jest błędny |
| `RESET_GAME` | brak | Reset rozgrywki na obu płytkach |
| `ACK` | numer sekwencji | Opcjonalne potwierdzenie odebrania ważnego pakietu |

Przykładowy format pakietu:

```text
start_byte       = 8'hA5
packet_type      = 4 bity
player_id        = 1 bit
payload          = 5 bitów, np. character_id 0..17
sequence_number  = 2..4 bity
checksum/parity  = opcjonalnie
```

Dla MVP wystarczy prosty i łatwy do debugowania protokół. Szybkość transmisji nie jest krytyczna.

## 12. Proponowana architektura modułów

| Moduł | Rola |
|---|---|
| `top_guess_who.sv` | Główny moduł strukturalny. Łączy zegary, reset, VGA, mysz, grę, renderery i komunikację |
| `guess_who_pkg.sv` | Stałe gry: 6 × 3, 18 postaci, enumy stanów, enumy pakietów, kolory |
| `vga_pkg.sv` | Stałe timingów VGA |
| `vga_timing.sv` | Generuje `hcount`, `vcount`, `hsync`, `vsync`, `blanking`, `frame_tick` |
| `MouseCtl.vhd` / `Ps2Interface.vhd` | Obsługa myszy PS/2 |
| `mouse_adapter.sv` | Synchronizacja sygnałów myszy, generowanie `left_click_pulse` i `right_click_pulse` |
| `hitbox_decoder.sv` | Mapowanie pozycji myszy na pole postaci albo przycisk |
| `game_core.sv` | Główna FSM gry: wybór, start, tury, eliminacje, zgadywanie, wynik |
| `pmod_comm_controller.sv` | Komunikacja Basys-Basys, odbiór i nadawanie pakietów |
| `board_renderer.sv` | Rysowanie planszy 6 × 3, ramek, eliminacji i feedbacku |
| `face_traits_rom.sv` | Cechy 18 postaci |
| `face_renderer.sv` | Proceduralne rysowanie twarzy na podstawie cech |
| `ui_renderer.sv` | Panel wybranej postaci, przyciski, tło UI |
| `text_renderer.sv` / `font_rom.sv` | Napisy ekranowe |
| `draw_mouse.sv` | Kursor myszy jako ostatnia warstwa obrazu |

Proponowany tor obrazu:

```text
vga_timing
  -> board_renderer
  -> ui_renderer / text_renderer
  -> draw_mouse
  -> wyjście VGA
```

## 13. Kodowanie postaci

Nie trzeba przechowywać 18 dużych bitmap. Zalecane jest rysowanie proceduralne twarzy na podstawie cech zapisanych w ROM-ie.

Przykładowe cechy:

| Bit | Cecha | Wpływ na rysowanie |
|---:|---|---|
| 0 | okulary | Prostokąty albo linie na oczach |
| 1 | czapka/opaska | Pasek nad głową |
| 2 | broda | Dolny fragment twarzy w ciemniejszym kolorze |
| 3 | jasne włosy | Jasny kolor włosów |
| 4 | ciemne włosy | Ciemny kolor włosów |
| 5 | długie włosy | Dodatkowe pasy po bokach głowy |
| 6 | uśmiech | Prosta linia lub segmenty ust |
| 7 | wariant skóry/twarzy | Inny odcień skóry albo kształt |

`face_traits_rom` powinien mieć dokładnie 18 wpisów, po jednym dla każdej postaci z planszy.

## 14. Zdarzenia systemowe

| Zdarzenie | Stan/kategoria | Reakcja systemu |
|---|---|---|
| LPM na postaci przed `START` | Wybór postaci | Ustaw `provisional_secret_id`, pokaż niebieską ramkę i kopię twarzy w panelu |
| LPM na innej postaci przed `START` | Wybór postaci | Zmień `provisional_secret_id`, poprzednia ramka wraca do szarej |
| Kliknięcie `START` | Wybór postaci | Zapisz `local_secret_id`, zablokuj zmianę, wyślij `READY` |
| Odebrano `READY` | Oczekiwanie na drugiego gracza | Ustaw `remote_ready`; jeśli lokalny gracz też gotowy, uruchom grę |
| PPM na postaci | Moja tura | Ustaw albo przełącz `eliminated_mask[id]` |
| LPM na postaci po starcie | Moja tura | Wyślij `GUESS(id)` |
| Odebrano `GUESS(id)` | Tura przeciwnika | Porównaj `id` z `local_secret_id` i odeślij wynik |
| Odebrano `RESULT_CORRECT` | Czekanie na wynik | Zielona ramka, `WYGRALES`, koniec gry |
| Odebrano `RESULT_WRONG` | Czekanie na wynik | Czerwona ramka przez ok. 3 s, eliminacja postaci, zmiana tury |
| Pozostała jedna aktywna postać | Moja tura | Wyślij `FINAL_CHECK(remaining_id)` |
| Kliknięcie `KONIEC TURY` | Moja tura | Wyślij `TURN_END` i przejdź do tury przeciwnika |
| Odebrano `TURN_END` | Tura przeciwnika | Przejdź do własnej tury |
| Kliknięcie `RESET GRY` | Dowolny stan | Wyślij `RESET_GAME`, wyczyść stan gry |
| Odebrano `RESET_GAME` | Dowolny stan | Wyczyść stan gry i wróć do wyboru postaci |

## 15. Kolejność realizacji

1. Uruchomić VGA i mysz PS/2 na jednej płytce.
2. Narysować statyczny ekran: plansza 6 × 3, panel wybranej twarzy po prawej, przyciski na dole.
3. Dodać `hitbox_decoder` i sprawdzić ID pól `0..17`.
4. Dodać wybór postaci przed `START`: niebieska ramka i kopia w panelu.
5. Dodać `game_core` bez komunikacji, w trybie lokalnym/debugowym.
6. Dodać eliminacje PPM i zgadywanie LPM lokalnie.
7. Dodać prostą komunikację i pakiety `READY`, `TURN_END`, `GUESS`, `RESULT_*`, `RESET_GAME`.
8. Połączyć dwie płytki i sprawdzić start gry po gotowości obu graczy.
9. Dodać obsługę błędnego strzału przez ok. 3 sekundy.
10. Dodać warunek końca przez pozostawienie jednej postaci.
11. Dodać napisy, poprawki graficzne i finalne twarze.
12. Przygotować testbenche, checklistę, film i bitstream.

## 16. Minimalny zakres działającej wersji MVP

MVP jest zaliczone, jeśli:

- na ekranie widać planszę 6 × 3, panel wybranej twarzy i przyciski,
- mysz działa i można klikać pola postaci,
- przed `START` można wybierać i zmieniać własną postać,
- `START` zapisuje postać i blokuje zmianę,
- gra startuje dopiero po `READY` z obu płytek,
- po starcie działa synchronizacja tur,
- PPM eliminuje postacie tylko podczas własnej tury,
- LPM zgaduje postać przeciwnika i czeka na odpowiedź drugiej płytki,
- poprawny strzał kończy grę zwycięstwem,
- błędny strzał pokazuje czerwoną ramkę przez około 3 sekundy, eliminuje postać i oddaje turę,
- `RESET GRY` działa z dowolnego stanu i resetuje obie płytki.

## 17. Ryzyka techniczne i decyzje

| Ryzyko/decyzja | Propozycja rozwiązania |
|---|---|
| VGA 1024 × 768 wymaga zegara pikselowego ok. 65 MHz | Wygenerować nowy clock wizard |
| Komunikacja dwóch płytek może być trudna do debugowania | Najpierw zrobić tryb loopback/symulacyjny |
| PS/2 i VGA mogą być w innych domenach zegarowych | Dodać `mouse_adapter` z synchronizacją i impulsami kliknięć |
| Duże bitmapy twarzy zużyją pamięć | Rysować twarze proceduralnie z prostych cech |
| Polskie znaki w napisach wymagają glifów | Na ekranie używać napisów bez polskich znaków: `WYGRALES`, `PRZEGRALES`, `TWOJA POSTAC` |
| Przypadkowa eliminacja postaci | Docelowo PPM jako toggle eliminacji |
| Niejasny reset | Konsekwentnie stosować reset asynchroniczny w logice gry |

## 18. Zasady dla osoby albo AI piszącej kod

1. Nie zmieniaj wymiarów planszy: projekt ma mieć **6 kolumn i 3 wiersze**.
2. Liczba postaci to **18**, nie 20.
3. Używaj `N_CHARACTERS = 18` i `eliminated_mask[17:0]`.
4. ID postaci liczymy jako `row * 6 + col`.
5. Panel po prawej pokazuje tylko lokalnie wybraną tajną twarz.
6. Nie wysyłaj `local_secret_id` do przeciwnika na starcie gry.
7. Synchronizuj tylko: gotowość, tury, zgadywanie, wyniki, reset i koniec gry.
8. Nie synchronizuj lokalnej maski eliminacji.
9. Kliknięcia eliminacji i zgadywania ignoruj, jeżeli `my_turn == 0`.
10. `RESET_GAME` ma działać z każdego stanu.
11. `top_guess_who.sv` powinien być możliwie strukturalny, bez upychania całej gry w jednym pliku.
12. Najpierw implementuj MVP, dopiero potem poprawiaj wygląd twarzy.

## 19. Sugerowane stałe do `guess_who_pkg.sv`

```systemverilog
package guess_who_pkg;
    localparam int BOARD_COLS   = 6;
    localparam int BOARD_ROWS   = 3;
    localparam int N_CHARACTERS = BOARD_COLS * BOARD_ROWS;

    localparam int CHAR_ID_W = 5; // wystarcza dla 0..17, kompatybilne z payloadem

    typedef enum logic [3:0] {
        PKT_HELLO          = 4'h0,
        PKT_READY          = 4'h1,
        PKT_TURN_END       = 4'h2,
        PKT_GUESS          = 4'h3,
        PKT_FINAL_CHECK    = 4'h4,
        PKT_RESULT_CORRECT = 4'h5,
        PKT_RESULT_WRONG   = 4'h6,
        PKT_RESET_GAME     = 4'h7,
        PKT_ACK            = 4'h8
    } packet_type_t;

    typedef enum logic [4:0] {
        S_RESET,
        S_WAIT_LINK,
        S_SELECT_SECRET,
        S_LOCAL_READY,
        S_GAME_START,
        S_MY_TURN,
        S_OPPONENT_TURN,
        S_WAIT_GUESS_RESULT,
        S_WRONG_GUESS_FEEDBACK,
        S_WIN,
        S_LOSE,
        S_GAME_OVER,
        S_COMM_ERROR
    } game_state_t;
endpackage
```

## 20. Podsumowanie

Projekt ma być prostą, czytelną i działającą implementacją gry „Zgadnij kto?” na dwóch płytkach Basys 3. Najważniejsze elementy to: plansza 6 × 3, panel wybranej twarzy po prawej, obsługa myszy, lokalna eliminacja postaci, tury, zgadywanie przez komunikację między płytkami i reset gry. Grafika twarzy może być prosta i proceduralna; kluczowe jest poprawne działanie logiki gry i komunikacji.
