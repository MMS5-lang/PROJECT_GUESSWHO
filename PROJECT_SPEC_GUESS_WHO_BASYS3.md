# Guess Who na Basys 3

## 1. Cel projektu

Celem projektu jest wykonanie sprzętowej wersji gry Guess Who na dwóch płytkach
Basys 3. Każdy gracz korzysta z osobnej płytki, osobnego monitora VGA oraz myszy
PS/2. Płytki komunikują się ze sobą przez UART wyprowadzony na złącze PMOD.

Dokument opisuje aktualny stan implementacji RTL: planszę 6 x 3, komunikację
UART między płytkami, stany maszyny gry, obsługę myszy PS/2, renderowanie VGA
1024 x 768 oraz sposób kodowania postaci.

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
| Reset | Wewnętrznie aktywny niskim stanem, asynchroniczna asercja i synchroniczne zwolnienie |
| Identyfikator gracza | `SW[0]`, jedna płytka ma 0, druga 1 |
| Top sprzętowy | `fpga/rtl/top_basys3.sv` |
| Top funkcjonalny gry | `rtl/top/top_vga.sv` |

Połączenie UART między płytkami:

- `JA2` jednej płytki należy połączyć z `JA3` drugiej płytki,
- `JA3` jednej płytki należy połączyć z `JA2` drugiej płytki,
- obie płytki muszą mieć wspólną masę GND,
- `JA1` jest używany jako wyjście pomocnicze z lustrem zegara pikselowego, a
  nie jako linia komunikacji gry.

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
- `RESET GRY`, który działa z każdego stanu gry.

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

1. Po zaprogramowaniu obu płytek należy ustawić różne wartości `SW[0]`:
   - gracz A: `SW[0] = 0`,
   - gracz B: `SW[0] = 1`.
2. Po resecie wewnętrzna maszyna gry startuje od `S_RESET`.
3. Następnie gra przechodzi do `S_WAIT_LINK`, jeżeli link z drugą płytką nie
   został jeszcze potwierdzony.
4. Kontroler komunikacji cyklicznie wysyła pakiety `HELLO`.
5. Gdy zostanie odebrany poprawny pakiet od drugiej płytki, ustawiane jest
   `link_ready`.
6. Po zestawieniu linku gra przechodzi do wyboru tajnej postaci.

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
7. W tej fazie wybrana postać na planszy jest wyróżniana niebieską ramką.

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
- kliknięcie `RESET GRY`: reset rozgrywki na obu płytkach.

Przycisk START wizualnie pełni wtedy funkcję `KONIEC TURY`. Jest rysowany jako
niebieski przycisk z białym napisem.

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

Po każdej eliminacji logika sprawdza, ile postaci pozostało aktywnych. Jeżeli
zostaje dokładnie jedna niewyeliminowana postać, projekt automatycznie wykonuje
finalne sprawdzenie tej postaci przez pakiet `FINAL_CHECK`.

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

### 5.8. Finalne sprawdzenie ostatniej postaci

Jeżeli po lokalnych eliminacjach zostaje dokładnie jedna aktywna postać,
`game_core` traktuje ją jako ostateczny wybór gracza.

Przebieg:

1. Aktywny gracz eliminuje postacie PPM.
2. Po eliminacji logika sprawdza liczbę niewyeliminowanych postaci.
3. Jeżeli została jedna postać, zostaje wyznaczone `remaining_id`.
4. Płytka wysyła `FINAL_CHECK(remaining_id)`.
5. Przeciwnik porównuje `remaining_id` ze swoim `local_secret_id`.
6. Poprawny wynik powoduje `S_WIN` u aktywnego gracza.
7. Błędny wynik powoduje `S_LOSE` u aktywnego gracza.

To zachowanie odpowiada sytuacji, w której gracz przez eliminacje doszedł do
jednej możliwej odpowiedzi.

### 5.9. Tura przeciwnika

Stan `S_OPPONENT_TURN` oznacza, że lokalny gracz czeka na ruch drugiej płytki.

W tym stanie:

- kliknięcia eliminacji i zgadywania nie zmieniają lokalnej gry,
- kursor zmienia się w klepsydrę,
- lokalna płytka może odebrać `GUESS`, `FINAL_CHECK`, `TURN_END` albo
  `RESET_GAME`.

Jeżeli przeciwnik wyśle `GUESS` albo `FINAL_CHECK`, lokalna płytka porównuje ID
z `local_secret_id` i odsyła odpowiedni wynik. Po błędnym `GUESS` lokalna płytka
nadal zostaje w `S_OPPONENT_TURN`, aby przeciwnik zdążył wyświetlić komunikat
`NIEPOPRAWNA POSTAC`. Do `S_MY_TURN` przechodzi dopiero po odebraniu `TURN_END`.

### 5.10. Reset gry

Przycisk `RESET GRY` działa z dowolnego stanu.

Kliknięcie resetu:

- wysyła `RESET_GAME` do drugiej płytki,
- czyści `eliminated_mask`,
- czyści `selected_id`,
- czyści `local_secret_id`,
- czyści `last_guess_id`,
- zeruje `has_secret`,
- zeruje `local_ready` i `remote_ready`,
- usuwa komunikaty wygranej/przegranej,
- czyści błąd komunikacji, liczniki ACK/retry, timeout i oczekujący pakiet,
- wraca do oczekiwania na link i wyboru postaci.

Odebrany pakiet `RESET_GAME` wykonuje analogiczny reset po stronie drugiej
płytki. Pakiet resetu jest traktowany idempotentnie, więc może wyczyścić
`comm_error` także wtedy, gdy wygląda jak retransmisja pakietu z tym samym
numerem sekwencyjnym. Jest to reset logiki gry i komunikacji, a nie pełny reset
układu FPGA ani clock wizarda.

### 5.11. Błąd komunikacji

Projekt ma obsługę błędu komunikacji. `pmod_comm_controller` ustawia
`comm_error`, gdy:

- po zestawieniu linku przez długi czas nie ma poprawnych pakietów,
- pakiet wymagający ACK nie zostanie potwierdzony mimo ponowień.

Po takim błędzie `game_core` przechodzi do `S_COMM_ERROR`. Na ekranie pojawia
się komunikat `ERROR NA LINK`. Kliknięcie ekranowego `RESET GRY` wysyła
`RESET_GAME`, czyści lokalny stan komunikacji i wraca do ponownego szukania
linku.

## 6. Sterowanie myszą i kursory

Projekt używa myszy PS/2 jako głównego interfejsu użytkownika.

| Akcja | Znaczenie |
| --- | --- |
| LPM na postaci w `S_SELECT_SECRET` | Wybór tajnej postaci |
| LPM na postaci w `S_MY_TURN` | Zgadywanie postaci przeciwnika |
| PPM na postaci w `S_MY_TURN` | Przełączenie eliminacji lokalnej |
| LPM na `START` | Zatwierdzenie tajnej postaci |
| LPM na `KONIEC TURY` | Oddanie tury przeciwnikowi |
| LPM na `RESET GRY` | Reset gry na obu płytkach |

Kursory:

| Tryb | Kiedy występuje |
| --- | --- |
| `CURSOR_POINTER` | Kursor poza aktywnymi hitboxami |
| `CURSOR_POINTER_HOVER` | Kursor nad planszą lub przyciskami |
| `CURSOR_BUSY` | Tura przeciwnika, czyli `S_OPPONENT_TURN` |

Bitmapy kursorów znajdują się w `rtl/assets/cursors`.

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
| `S_FINAL_CHECK` | 9 | Po pozostawieniu jednej postaci oczekiwany jest wynik finalnego sprawdzenia |
| `S_WIN` | 10 | Lokalny gracz wygrał |
| `S_LOSE` | 11 | Lokalny gracz przegrał |
| `S_GAME_OVER` | 12 | Stan końcowy zdefiniowany w typie; obecnie normalna ścieżka gry używa `S_WIN` i `S_LOSE` |
| `S_COMM_ERROR` | 13 | Błąd komunikacji albo utrata linku |

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
| `S_MY_TURN` | PPM zostawia jedną aktywną postać | `S_FINAL_CHECK` |
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
| dowolny stan | `RESET_GRY` lub `RESET_GAME` | `S_WAIT_LINK` |
| dowolny stan | `comm_error` | `S_COMM_ERROR` |

## 8. Dane przechowywane przez logikę gry

Najważniejsze rejestry i sygnały stanu w `game_core.sv`:

| Sygnał | Znaczenie |
| --- | --- |
| `state` | Aktualny stan FSM gry |
| `eliminated_mask[17:0]` | Lokalna maska eliminacji; 1 oznacza postać wyeliminowaną |
| `selected_id[4:0]` | Aktualnie kliknięta postać przed zatwierdzeniem START |
| `local_secret_id[4:0]` | Zatwierdzona tajna postać lokalnego gracza |
| `last_guess_id[4:0]` | Ostatnio zgadywana albo finalnie sprawdzana postać |
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
- typ pakietu jest wspierany,
- `player_id` nie jest równy lokalnemu `player_id`,
- payload jest poprawny dla danego typu pakietu.

Typy pakietów:

| Typ | Kod | Payload | Znaczenie |
| --- | ---: | --- | --- |
| `PKT_HELLO` | 0 | 0 | Okresowe potwierdzenie obecności drugiej płytki |
| `PKT_STATUS` | 1 | zależnie od użycia | Typ zarezerwowany; parser go akceptuje, ale FSM gry go nie używa |
| `PKT_READY` | 2 | 0 | Gracz zatwierdził swoją postać |
| `PKT_TURN_END` | 3 | 0 | Aktywny gracz kończy turę |
| `PKT_GUESS` | 4 | `character_id` | Gracz zgaduje postać przeciwnika |
| `PKT_FINAL_CHECK` | 5 | `character_id` | Sprawdzenie jedynej pozostałej postaci |
| `PKT_RESULT_CORRECT` | 6 | `character_id` | Wynik poprawny |
| `PKT_RESULT_WRONG` | 7 | `character_id` | Wynik błędny |
| `PKT_RESET_GAME` | 8 | 0 | Reset gry na obu płytkach |
| `PKT_ACK` | 9 | typ potwierdzanego pakietu | Potwierdzenie pakietu wymagającego ACK |
| `PKT_ERROR` | 10 | 0 | Typ zarezerwowany; parser go akceptuje, ale FSM gry go nie używa |

Pakiety `READY`, `TURN_END`, `GUESS`, `FINAL_CHECK`, `RESULT_CORRECT`,
`RESULT_WRONG` i `RESET_GAME` wymagają potwierdzenia ACK. Jeżeli ACK nie wróci w
zadanym czasie, pakiet jest wysyłany ponownie z tym samym numerem sekwencyjnym.
Odbiornik potwierdza duplikaty, ale nie generuje drugi raz tego samego zdarzenia
gry. Wyjątkiem jest `RESET_GAME`, który jest idempotentny i może ponownie
wyczyścić stan gry oraz komunikacji, jeśli przychodzi jako retransmisja po
błędzie linku.

## 10. Renderowanie obrazu

Tor obrazu jest zbudowany warstwowo:

```text
vga_timing
  -> draw_bg
  -> ui_renderer
  -> face_renderer
  -> board_renderer
  -> text_renderer
  -> draw_mouse
  -> wyjście VGA
```

Rola warstw:

| Moduł | Rola |
| --- | --- |
| `vga_timing.sv` | Generuje liczniki, synchronizację i blanking VGA |
| `draw_bg.sv` | Rysuje tło, planszę i siatkę |
| `ui_renderer.sv` | Rysuje panel oraz przyciski |
| `face_renderer.sv` | Rysuje twarze na planszy i w panelu |
| `board_renderer.sv` | Nakłada eliminacje, zaznaczenia i ramki stanu |
| `text_renderer.sv` | Nakłada napisy ekranowe; moduł jest potokowany, aby zamknąć timing toru VGA |
| `draw_mouse.sv` | Nakłada kursor jako ostatnią warstwę |

`text_renderer.sv` działa w kilku etapach zegarowych: najpierw rejestruje piksel
wejściowy i stan gry, następnie wybiera aktywny napis, potem wyznacza znak oraz
pozycję w fontcie, a na końcu składa wynikowy kolor RGB. Ten potok usuwa długą
ścieżkę kombinacyjną między `board_renderer` i wyjściowym rejestrem RGB tekstu.
Po tej zmianie implementacja Vivado spełnia timing dla zegara 65 MHz.

## 11. Pomysł na kodowanie postaci

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
| 0 | `0000_0110_1000` |
| 1 | `0100_0101_1000` |
| 2 | `0010_1000_0000` |
| 3 | `1011_1000_0001` |
| 4 | `0000_1011_1100` |
| 5 | `0000_0100_0001` |
| 6 | `1000_0010_1010` |
| 7 | `0011_0101_1000` |
| 8 | `0000_1000_0000` |
| 9 | `1000_0111_1001` |
| 10 | `0100_1000_1100` |
| 11 | `0010_0011_0000` |
| 12 | `0001_1010_1000` |
| 13 | `1000_0101_0000` |
| 14 | `0100_0110_1011` |
| 15 | `0000_1001_1000` |
| 16 | `0010_0110_0100` |
| 17 | `1001_0001_0000` |

Taki sposób kodowania oszczędza pamięć i pozwala tworzyć wiele postaci przez
kombinowanie tych samych elementów graficznych.

## 12. Stany ekranowe i informacja dla gracza

Projekt informuje gracza o stanie gry na dwa sposoby:

- przez napisy w panelu bocznym,
- przez zmianę kursora.

Przykłady komunikatów ekranowych:

| Stan | Komunikat |
| --- | --- |
| `S_WAIT_LINK` | `CZEKAM / NA LINK` |
| `S_SELECT_SECRET` | `WYBIERZ / SWOJA / POSTAC` |
| `S_LOCAL_READY` | `POCZEKAJ / NA RYWALA` |
| `S_WAIT_GUESS_RESULT` | `CZEKAM / NA WYNIK` |
| `S_FINAL_CHECK` | `OSTATNIA / POSTAC` |
| `S_WRONG_GUESS_FEEDBACK` | `NIEPOPRAWNA / POSTAC` |
| `S_WIN` | `WYGRALES` |
| `S_LOSE` | `PRZEGRALES` |
| `S_COMM_ERROR` | `ERROR / NA LINK` |

Tura przeciwnika nie jest opisywana dodatkowym tekstem, ponieważ w obecnym
projekcie jest sygnalizowana klepsydrą (`CURSOR_BUSY`).

## 13. Tabela zdarzeń do raportu

| Zdarzenie | Stan/kategoria | Reakcja systemu w obecnym projekcie |
| --- | --- | --- |
| Poprawny pakiet od drugiej płytki | `S_WAIT_LINK` | Ustawia `link_ready` i pozwala przejść do wyboru postaci |
| LPM na postaci przed START | `S_SELECT_SECRET` | Ustawia `selected_id`, ustawia `has_secret`, pokazuje postać w panelu |
| LPM na innej postaci przed START | `S_SELECT_SECRET` | Zmienia `selected_id`; poprzedni wybór przestaje być aktywny |
| Kliknięcie START bez wybranej postaci | `S_SELECT_SECRET` | Nie zatwierdza gry, bo `has_secret == 0` |
| Kliknięcie START po wyborze postaci | `S_SELECT_SECRET` | Zapisuje `local_secret_id`, ustawia `local_ready`, wysyła `READY` |
| Odebrano `READY` | Przed startem gry | Ustawia `remote_ready` |
| `local_ready && remote_ready` | `S_LOCAL_READY` | Przejście do `S_GAME_START` |
| `player_id == 0` | `S_GAME_START` | Lokalna płytka zaczyna turę |
| `player_id == 1` | `S_GAME_START` | Lokalna płytka czeka na przeciwnika |
| PPM na postaci | `S_MY_TURN` | Przełącza bit `eliminated_mask[id]` |
| PPM na ostatniej aktywnej postaci | `S_MY_TURN` | Kliknięcie jest ignorowane, aby nie zostawić planszy bez żadnej postaci |
| Po eliminacji zostaje jedna postać | `S_MY_TURN` | Wysyła `FINAL_CHECK(remaining_id)` |
| LPM na postaci po starcie | `S_MY_TURN` | Wysyła `GUESS(id)` i przechodzi do oczekiwania na wynik |
| Kliknięcie KONIEC TURY | `S_MY_TURN` | Wysyła `TURN_END` i przechodzi do tury przeciwnika |
| Odebrano `TURN_END` | `S_OPPONENT_TURN` | Przejście do `S_MY_TURN` |
| Odebrano `GUESS(id)` | `S_OPPONENT_TURN` | Porównuje `id` z `local_secret_id` i odsyła wynik |
| Odebrano `FINAL_CHECK(id)` | `S_OPPONENT_TURN` | Porównuje `id` z `local_secret_id` i odsyła wynik |
| Odebrano `RESULT_CORRECT` po `GUESS` | `S_WAIT_GUESS_RESULT` | Przejście do `S_WIN` |
| Odebrano `RESULT_WRONG` po `GUESS` | `S_WAIT_GUESS_RESULT` | Przejście do `S_WRONG_GUESS_FEEDBACK` |
| Koniec feedbacku błędnego strzału | `S_WRONG_GUESS_FEEDBACK` | Wysyła `TURN_END` i przechodzi do `S_OPPONENT_TURN` |
| Brak wyniku po `GUESS` | `S_WAIT_GUESS_RESULT` | Po 600 ramkach przechodzi do `S_COMM_ERROR` |
| Odebrano poprawny wynik po `FINAL_CHECK` | `S_FINAL_CHECK` | Przejście do `S_WIN` |
| Odebrano błędny wynik po `FINAL_CHECK` | `S_FINAL_CHECK` | Przejście do `S_LOSE` |
| Brak wyniku po `FINAL_CHECK` | `S_FINAL_CHECK` | Po 600 ramkach przechodzi do `S_COMM_ERROR` |
| Kliknięcie RESET GRY | Dowolny stan | Wysyła `RESET_GAME`, czyści lokalny stan gry i stan komunikacji |
| Odebrano `RESET_GAME` | Dowolny stan | Czyści lokalny stan gry i stan komunikacji |
| Brak ACK po retransmisjach | Komunikacja | Ustawia `comm_error`, gra przechodzi do `S_COMM_ERROR` |
| Długi brak poprawnych pakietów | Komunikacja | Ustawia `comm_error`, gra przechodzi do `S_COMM_ERROR` |

## 14. Moduły projektu

| Moduł | Rola w projekcie |
| --- | --- |
| `top_basys3.sv` | Top sprzętowy dla Basys 3: piny, zegary, reset, PMOD, VGA, PS/2 |
| `top_vga.sv` | Główny top funkcjonalny gry |
| `guess_who_pkg.sv` | Stany gry, typy pakietów, liczba postaci, tryby kursora |
| `vga_pkg.sv` | Timing VGA i geometria UI |
| `vga_timing.sv` | Generacja liczników i synchronizacji VGA |
| `MouseCtl.vhd`, `Ps2Interface.vhd` | Obsługa myszy PS/2 |
| `mouse_adapter.sv` | Synchronizacja myszy i impulsy kliknięć |
| `hitbox_decoder.sv` | Mapowanie kliknięć na planszę i przyciski |
| `game_core.sv` | Główna FSM gry |
| `pmod_comm_controller.sv` | Pakiety UART, ACK/retry, timeout, zdarzenia przeciwnika |
| `uart_byte_link.sv` | Adapter bajtowy do rdzenia UART |
| `draw_bg.sv` | Tło i siatka planszy |
| `ui_renderer.sv` | Panel i przyciski |
| `face_traits_rom.sv` | Cechy postaci |
| `face_renderer.sv` | Rysowanie twarzy |
| `board_renderer.sv` | Eliminacje, zaznaczenia i ramki |
| `text_renderer.sv`, `font_rom.sv` | Napisy ekranowe |
| `cursor_mode_controller.sv` | Wybór trybu kursora |
| `draw_mouse.sv` | Rysowanie kursora |

## 15. Minimalna procedura uruchomienia

1. Zaprogramować obie płytki tym samym bitstreamem.
2. Ustawić `SW[0] = 0` na pierwszej płytce i `SW[0] = 1` na drugiej.
3. Połączyć UART: `JA2` pierwszej płytki z `JA3` drugiej, `JA3` pierwszej z
   `JA2` drugiej oraz wspólne GND.
4. Podłączyć osobne monitory VGA albo testować płytki po kolei na jednym
   monitorze.
5. Podłączyć myszy PS/2.
6. Zresetować układ przyciskiem `BTNC`, jeśli obraz lub stan gry nie startuje od
   początku.
7. Poczekać na link.
8. Na obu płytkach wybrać tajną postać LPM.
9. Na obu płytkach kliknąć START.
10. Gracz z `SW[0] = 0` wykonuje pierwszy ruch.
11. Sprawdzić eliminację PPM, zakończenie tury, zgadywanie LPM oraz reakcję drugiej
    płytki.
12. Sprawdzić reset gry przyciskiem `RESET GRY`.
