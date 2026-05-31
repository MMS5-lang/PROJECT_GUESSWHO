# Opis modułów RTL projektu Guess Who

Ten dokument opisuje strukturę części RTL projektu Guess Who przygotowanego na
platformę Basys 3. Jego celem jest pokazanie, za co odpowiadają poszczególne
moduły, jak są ze sobą połączone i gdzie należy szukać konkretnych fragmentów
funkcjonalności. Dokument nie jest opisem każdej pojedynczej linii kodu, tylko
technicznym przewodnikiem po architekturze projektu.

Projekt można podzielić na kilka głównych obszarów:

- integracja z płytką Basys 3,
- generacja obrazu VGA,
- logika gry Guess Who,
- obsługa myszy PS/2 i kursora,
- komunikacja UART między dwiema płytkami,
- małe moduły pomocnicze, takie jak synchronizacja resetu, debounce i FIFO.

Najważniejsze pliki startowe to:

- `fpga/rtl/top_basys3.sv`, czyli top sprzętowy dla Basys 3,
- `rtl/top/top_vga.sv`, czyli główny top funkcjonalny gry,
- `rtl/game/game_core.sv`, czyli maszyna stanów gry,
- `rtl/comm/pmod_comm_controller.sv`, czyli kontroler komunikacji między
  płytkami,
- `rtl/vga/vga_pkg.sv`, czyli wspólna geometria ekranu, planszy i przycisków.

## Ogólny przepływ danych w projekcie

Projekt działa w sposób potokowy i modułowy. Z punktu widzenia działania gry
najważniejszy jest następujący przepływ:

1. `top_basys3.sv` odbiera fizyczne sygnały z płytki, generuje zegary i reset.
2. `top_vga.sv` łączy wszystkie moduły funkcjonalne projektu.
3. `MouseCtl.vhd` odbiera dane z myszy PS/2, a `mouse_adapter.sv` zamienia je na
   współrzędne i impulsy kliknięć w domenie VGA.
4. `hitbox_decoder.sv` sprawdza, czy kliknięcie trafiło w planszę, przycisk
   START/KONIEC TURY albo RESET GRY.
5. `game_core.sv` na podstawie kliknięć i komunikatów od drugiej płytki zmienia
   stan gry.
6. `pmod_comm_controller.sv` zamienia zdarzenia gry na pakiety UART i odbiera
   pakiety z drugiej płytki.
7. Moduły renderujące tworzą kolejne warstwy obrazu VGA: tło, UI, twarze,
   zaznaczenia, tekst i kursor.

Obraz VGA jest tworzony jako łańcuch kolejnych warstw. Każdy renderer dostaje
aktualny piksel z poprzedniego modułu i może zostawić go bez zmian albo nadpisać
nowym kolorem. Dzięki temu łatwo oddzielić rysowanie tła, planszy, postaci,
tekstów i kursora.

## Top level i integracja z Basys 3

### `fpga/rtl/top_basys3.sv`

Jest to najwyższy moduł syntezowalny dla płytki Basys 3. Odpowiada za połączenie
logiki projektu z rzeczywistymi pinami płytki. W tym pliku znajdują się sygnały
VGA, PS/2, PMOD UART, przełącznik `SW[0]`, przycisk `btnC` oraz zegar wejściowy.

Najważniejsze zadania modułu:

- podłącza `SW[0]` jako identyfikator gracza `player_id`,
- wystawia UART TX na `JA2`,
- odbiera UART RX z `JA3`,
- przekazuje linie PS/2 do kontrolera myszy,
- generuje zegary 100 MHz i 65 MHz przez `clk_wiz_0`,
- stabilizuje zwolnienie resetu przez `debounce`,
- synchronizuje reset osobno dla domen 65 MHz i 100 MHz,
- instancjonuje główny moduł gry `top_vga`.

Ten plik jest istotny przy uruchamianiu projektu na sprzęcie. Jeżeli na płytce
nie działa reset, obraz VGA, identyfikator gracza albo komunikacja przez PMOD,
to właśnie tutaj należy sprawdzić przypisania sygnałów i połączenia z modułem
funkcjonalnym.

### `fpga/rtl/clk_wiz_0.v`

Jest to wrapper wygenerowanego przez Vivado modułu clock wizard. Ma prosty
interfejs: przyjmuje zegar wejściowy `clk`, a wystawia `clk100MHz`,
`clk65MHz` i sygnał `locked`.

Moduł pełni rolę technicznego opakowania dla wygenerowanego IP. W normalnej
pracy projektu nie powinno się go ręcznie modyfikować. Zmiany wykonuje się
raczej przez ponowną konfigurację IP w Vivado.

### `fpga/rtl/clk_wiz_0_clk_wiz.v`

Jest to właściwa implementacja clock wizarda z prymitywem `MMCME2_ADV`. Moduł
tworzy dwa zegary:

- 100 MHz, używany między innymi przez kontroler myszy PS/2 i debounce resetu,
- 65 MHz, używany jako zegar pikselowy dla trybu VGA 1024 x 768 oraz dla
  większości logiki gry.

Plik jest wygenerowany automatycznie. W dokumentacji projektu warto wiedzieć, że
istnieje, ale zwykle nie analizuje się go tak jak ręcznie pisanego RTL.

## Pakiety, typy i geometria

### `rtl/game/guess_who_pkg.sv`

Pakiet `guess_who_pkg` zawiera wspólne definicje używane przez logikę gry,
komunikację i kursory. Dzięki temu stany gry, typy pakietów oraz liczba postaci
nie są powielane w wielu plikach.

Najważniejsze elementy pakietu:

- `BOARD_COLS`, `BOARD_ROWS`, `N_CHARACTERS` i `CHAR_COUNT` definiują planszę
  6 x 3, czyli 18 postaci,
- `CHAR_ID_W` określa szerokość identyfikatora postaci,
- `game_state_t` zawiera wszystkie stany maszyny gry, na przykład
  `S_SELECT_SECRET`, `S_MY_TURN`, `S_OPPONENT_TURN`, `S_WIN`, `S_LOSE` i
  `S_COMM_ERROR`,
- `packet_type_t` opisuje typy pakietów UART, na przykład `PKT_READY`,
  `PKT_GUESS`, `PKT_RESULT_CORRECT`, `PKT_RESET_GAME` i `PKT_ACK`,
- `cursor_mode_t` opisuje tryby kursora: zwykły kursor, kursor nad hitboxem i
  kursor oczekiwania.

Do tego pliku należy zajrzeć, gdy dodawany jest nowy stan gry, nowy typ pakietu
komunikacyjnego albo nowy tryb kursora.

### `rtl/vga/vga_pkg.sv`

Pakiet `vga_pkg` zawiera parametry obrazu i geometrii interfejsu użytkownika.
Jest to centralne miejsce, w którym zdefiniowano rozdzielczość VGA, położenie
planszy, rozmiar pól, położenie panelu oraz położenie przycisków.

Najważniejsze informacje w tym pliku:

- aktywny obszar obrazu ma 1024 x 768 pikseli,
- plansza ma 6 kolumn i 3 wiersze,
- pojedyncze pole planszy ma rozmiar `CELL_W` x `CELL_H`,
- `BOARD_X` i `BOARD_Y` określają położenie lewego górnego rogu planszy,
- `PANEL_X` i `PANEL_Y` określają położenie panelu wybranej postaci,
- `START_X`, `START_Y`, `RESET_X`, `RESET_Y`, `BUTTON_W` i `BUTTON_H`
  określają geometrię przycisków.

Ten plik jest szczególnie ważny, ponieważ z jego stałych korzystają zarówno
renderery, jak i dekoder hitboxów. Jeżeli przesuwamy planszę albo przyciski, to
zmiana powinna być wykonana tutaj, aby logika kliknięć i obraz pozostały
spójne.

### `rtl/vga/vga_if.sv`

`vga_if` jest interfejsem SystemVerilog używanym do przekazywania aktualnego
piksela pomiędzy warstwami renderowania.

Interfejs przenosi:

- aktualny licznik poziomy `hcount`,
- aktualny licznik pionowy `vcount`,
- sygnały synchronizacji `hsync` i `vsync`,
- sygnały blankingu `hblnk` i `vblnk`,
- 12-bitowy kolor RGB444 `rgb`.

Dzięki temu każdy renderer ma taki sam sposób komunikacji z poprzednią i następną
warstwą. Moduł może odczytać pozycję piksela oraz kolor wejściowy, a następnie
wystawić zmodyfikowany piksel dalej.

## Generacja obrazu VGA

### `rtl/vga/vga_timing.sv`

Moduł `vga_timing` generuje liczniki i sygnały czasowe dla obrazu VGA
1024 x 768. Jest to podstawowy moduł w torze obrazu.

Moduł odpowiada za:

- zliczanie aktualnej pozycji poziomej `hcount`,
- zliczanie aktualnej pozycji pionowej `vcount`,
- generowanie impulsu synchronizacji poziomej `hsync`,
- generowanie impulsu synchronizacji pionowej `vsync`,
- oznaczenie obszarów blankingu przez `hblnk` i `vblnk`.

Pozostałe moduły renderujące nie generują samodzielnie czasu VGA. One tylko
korzystają z `hcount` i `vcount`, żeby wiedzieć, który piksel jest aktualnie
rysowany.

### `rtl/render/draw_bg.sv`

`draw_bg` jest pierwszą warstwą graficzną po generatorze timingu. Tworzy bazowy
obraz planszy.

Moduł rysuje:

- tło poza planszą,
- białe pola planszy,
- czarną zewnętrzną ramkę planszy,
- linie siatki oddzielające 18 pól postaci.

Jest to moduł czysto renderujący. Nie zna zasad gry, nie wie, która postać jest
wybrana ani wyeliminowana. Jego zadaniem jest przygotowanie statycznej podstawy,
na której kolejne warstwy rysują postacie, zaznaczenia i tekst.

### `rtl/render/ui_renderer.sv`

`ui_renderer` rysuje podstawowe elementy panelu bocznego:

- prostokąt panelu "TWOJA POSTAĆ",
- przycisk START albo KONIEC TURY,
- przycisk RESET GRY.

Kolor przycisku START/KONIEC TURY zależy od aktualnego stanu gry. Na przykład w
fazie wyboru postaci przycisk może być zielony, w turze gracza niebieski, a w
stanach oczekiwania może mieć kolor informujący, że gracz czeka na dalszy etap.

Ten moduł odpowiada za tło elementów UI, ale nie rysuje tekstu. Napisy są
nakładane później przez `text_renderer.sv`.

### `rtl/render/face_traits_rom.sv`

`face_traits_rom` jest małym ROM-em opisującym cechy każdej z 18 postaci. Dla
danego `char_id` zwraca 12-bitowy wektor `traits`.

Wektor cech decyduje między innymi o tym, czy postać ma:

- brodę,
- czapkę z daszkiem,
- kapelusz,
- okulary zwykłe,
- okulary przeciwsłoneczne,
- krótkie albo długie włosy,
- określony kolor włosów,
- określony kolor skóry,
- pejsy.

Ten plik nie rysuje grafiki. On tylko opisuje, jakie elementy powinny zostać
użyte przez `face_renderer.sv`.

### `rtl/render/face_renderer.sv`

`face_renderer` jest głównym modułem odpowiedzialnym za rysowanie postaci.
Korzysta z bitmap zapisanych w plikach `.dat` oraz z cech zwracanych przez
`face_traits_rom`.

Moduł nakłada na pole postaci kolejne elementy:

- kształt głowy,
- włosy,
- brodę,
- okulary,
- czapkę lub kapelusz,
- pejsy.

Ten sam renderer rysuje twarze zarówno na planszy 6 x 3, jak i w panelu
"TWOJA POSTAĆ", jeżeli gracz wybrał już swoją tajną postać. Wewnątrz modułu
istnieje potok, ponieważ bitmapy są czytane z pamięci ROM. Moduł musi więc
opóźnić współrzędne i sygnały VGA tak, aby kolor z ROM-u pasował do właściwego
piksela.

Do tego pliku należy zajrzeć, gdy zmieniany jest wygląd postaci, położenie
elementów twarzy albo sposób kolorowania skóry, włosów i dodatków.

### `rtl/render/board_renderer.sv`

`board_renderer` nakłada na planszę informacje wynikające ze stanu gry. Jest to
warstwa logiczno-wizualna, która pokazuje decyzje gracza na ekranie.

Moduł odpowiada za:

- zaznaczenie wybranej tajnej postaci podczas wyboru,
- oznaczanie wyeliminowanych postaci,
- zaznaczenie ostatnio błędnie zgadniętej postaci,
- kolorowanie ramki panelu wybranej postaci zależnie od stanu gry.

Ten moduł nie decyduje, które postacie są wyeliminowane. Otrzymuje gotową maskę
`eliminated_mask` z `game_core.sv` i tylko przekłada ją na obraz. Dzięki temu
logika gry i logika rysowania pozostają rozdzielone.

## Teksty i komunikaty ekranowe

### `rtl/text/font_rom.sv`

`font_rom` zawiera prosty font 5 x 7 pikseli. Dla podanego kodu znaku i numeru
wiersza zwraca pięć bitów opisujących piksele tego wiersza.

Font jest niewielki i zawiera litery potrzebne do napisów używanych w projekcie.
Nie obsługuje pełnego zestawu znaków ASCII, tylko te znaki, które są faktycznie
potrzebne w UI.

### `rtl/text/text_renderer.sv`

`text_renderer` nakłada tekst na gotowy obraz VGA. Korzysta z `font_rom.sv`,
wylicza pozycję znaku i wybiera odpowiedni kolor tekstu.

Moduł rysuje między innymi:

- napisy na przyciskach: `START`, `KONIEC TURY`, `RESET GRY`,
- napis nad panelem: `TWOJA POSTAĆ`,
- komunikaty wyboru: `WYBIERZ SWOJĄ POSTAĆ`,
- komunikat oczekiwania: `POCZEKAJ NA RYWALA`,
- komunikaty linku i wyniku: `CZEKAM NA LINK`, `CZEKAM NA WYNIK`,
- komunikaty końcowe: `WYGRAŁEŚ`, `PRZEGRAŁEŚ`,
- komunikat błędu komunikacji: `ERROR NA LINK`.

Ten moduł jest miejscem, w którym stan gry zostaje zamieniony na czytelny
komunikat dla użytkownika. Jeżeli prowadzący pyta, gdzie projekt informuje
gracza o aktualnej fazie gry, odpowiedź znajduje się właśnie tutaj oraz w
`cursor_mode_controller.sv`, który dodatkowo pokazuje turę przeciwnika przez
klepsydrę.

## Logika gry

### `rtl/game/game_core.sv`

`game_core` jest centralną maszyną stanów gry Guess Who. Ten moduł nie zajmuje
się rysowaniem ani fizycznym UART-em. Jego zadaniem jest wyłącznie utrzymywanie
stanu rozgrywki i generowanie zdarzeń dla innych modułów.

Moduł obsługuje:

- oczekiwanie na połączenie z drugą płytką,
- wybór tajnej postaci,
- zatwierdzenie gotowości lokalnego gracza,
- zapamiętanie gotowości przeciwnika,
- rozpoczęcie gry i wybór pierwszej tury na podstawie `player_id`,
- turę lokalnego gracza,
- turę przeciwnika,
- eliminowanie postaci prawym kliknięciem,
- zgadywanie postaci lewym kliknięciem,
- finalne sprawdzenie ostatniej pozostałej postaci,
- odpowiedzi na zgadywanie przeciwnika,
- stan wygranej i przegranej,
- reset gry,
- przejście do stanu `S_COMM_ERROR` przy błędzie komunikacji.

Ważną cechą tego modułu jest to, że nie wysyła samodzielnie pakietów UART. Zamiast
tego wystawia impulsy takie jak `send_ready`, `send_guess`, `send_turn_end` albo
`send_result`. Dopiero `pmod_comm_controller.sv` zamienia te impulsy na ramki
UART. Takie rozdzielenie powoduje, że zasady gry są oddzielone od szczegółów
komunikacji.

Jeżeli trzeba zmienić reguły rozgrywki, kolejność stanów, reakcję na kliknięcia
albo zachowanie po wyniku zgadywania, to najważniejszym plikiem jest
`game_core.sv`.

## Obsługa myszy, kliknięć i kursorów

### `rtl/mouse/MouseCtl.vhd`

`MouseCtl` jest kontrolerem myszy PS/2 napisanym w VHDL. Odpowiada za
inicjalizację myszy, włączenie raportowania oraz odbiór pakietów ruchu i
przycisków.

W projekcie moduł wystawia:

- pozycję kursora `xpos` i `ypos`,
- stan lewego, środkowego i prawego przycisku,
- informację o nowym zdarzeniu,
- pozycję lub ruch rolki myszy jako `zpos`.

Jest to moduł niskopoziomowy i w typowych zmianach gry nie trzeba go
modyfikować. Jego obecność jest jednak istotna, ponieważ projekt korzysta z
myszy jako podstawowego urządzenia wejściowego.

### `rtl/mouse/Ps2Interface.vhd`

`Ps2Interface` jest jeszcze niższą warstwą obsługi PS/2. Moduł odpowiada za
fizyczną komunikację po liniach `ps2_clk` i `ps2_data`.

Obsługuje:

- ramki PS/2,
- bity startu, danych, parzystości i stopu,
- potwierdzenia ACK,
- tryb open-collector linii PS/2,
- zgłaszanie błędów transmisji do `MouseCtl`.

`MouseCtl.vhd` korzysta z tego modułu jako warstwy transportowej. W praktyce
większość logiki projektu nie komunikuje się bezpośrednio z `Ps2Interface`.

### `rtl/mouse/mouse_adapter.sv`

`mouse_adapter` łączy świat VHDL-owego kontrolera PS/2 z resztą projektu
SystemVerilog. Synchronizuje sygnały myszy do domeny zegara pikselowego 65 MHz
i zamienia poziomy przycisków na jednocykliczne impulsy kliknięć.

Moduł odpowiada za:

- synchronizację współrzędnych myszy,
- synchronizację lewego i prawego przycisku,
- ograniczenie pozycji kursora do aktywnego obszaru VGA,
- wygenerowanie `left_click_pulse` i `right_click_pulse`.

Dzięki temu `game_core.sv` nie musi sprawdzać, jak długo użytkownik trzyma
przycisk myszy. Otrzymuje tylko pojedyncze zdarzenie kliknięcia.

### `rtl/ui/hitbox_decoder.sv`

`hitbox_decoder` sprawdza, w jaki obszar ekranu kliknął użytkownik. Na podstawie
pozycji kursora i impulsów kliknięcia generuje sygnały dla logiki gry.

Moduł rozpoznaje:

- kliknięcie w pole planszy,
- ID klikniętej postaci,
- kliknięcie przycisku START/KONIEC TURY,
- kliknięcie przycisku RESET GRY,
- rozróżnienie lewego i prawego kliknięcia na planszy.

Ten moduł musi być zgodny z geometrią w `vga_pkg.sv`. Jeżeli wizualnie przesunie
się planszę albo przyciski, a hitboxy nie zostaną zaktualizowane, użytkownik
będzie klikał w inne miejsce niż to, które widzi na ekranie.

### `rtl/mouse/cursor_mode_controller.sv`

`cursor_mode_controller` wybiera, który kursor powinien być aktualnie widoczny.

W projekcie są trzy tryby:

- zwykły kursor, gdy mysz nie znajduje się nad aktywnym obszarem,
- kursor hover, gdy mysz jest nad planszą albo przyciskiem,
- klepsydra, gdy trwa tura przeciwnika.

Ten moduł nie rysuje bitmapy kursora. On tylko wybiera tryb, który następnie
jest używany przez `draw_mouse.sv`.

### `rtl/mouse/draw_mouse.sv`

`draw_mouse` jest ostatnią warstwą toru VGA. Nakłada wybraną bitmapę kursora na
gotowy obraz.

Moduł korzysta z trzech plików `.dat`:

- `pointer_b.dat`,
- `pointer_toon_b.dat`,
- `busy_hourglass_outline_detail.dat`.

Kursor jest rysowany jako obraz 64 x 64 piksele. Piksel o kolorze `12'h000`
pełni rolę przezroczystości, więc nie nadpisuje obrazu pod spodem. Dzięki temu
kształt kursora może mieć nieregularną formę, mimo że ROM ma prostokątny rozmiar.

## Komunikacja UART między płytkami

### `rtl/comm/pmod_comm_controller.sv`

`pmod_comm_controller` jest głównym modułem komunikacji między dwiema płytkami
Basys 3. Łączy logikę gry z fizycznym UART-em.

Moduł odpowiada za:

- tworzenie pakietów na podstawie sygnałów `send_*` z `game_core.sv`,
- odbiór pakietów z drugiej płytki,
- sprawdzanie bajtu startowego,
- sprawdzanie typu pakietu,
- sprawdzanie identyfikatora gracza,
- sprawdzanie sumy kontrolnej,
- sprawdzanie poprawności payloadu,
- odrzucanie pakietów wysłanych przez tego samego gracza,
- wystawianie zdarzeń `opponent_*` dla `game_core.sv`,
- obsługę wyników zgadywania i finalnego sprawdzenia,
- okresowe pakiety HELLO,
- potwierdzenia ACK,
- retransmisję ważnych pakietów,
- timeout komunikacji i sygnał `comm_error`.

Pakiet gry składa się z sześciu bajtów:

- bajt startowy,
- typ pakietu,
- identyfikator gracza,
- payload,
- numer sekwencyjny,
- suma kontrolna.

Ten moduł jest kluczowy dla gry na dwóch płytkach. Jeżeli komunikacja między
Basysami nie działa, trzeba sprawdzić zarówno ten plik, jak i fizyczne
połączenie PMOD: TX jednej płytki musi być podłączony do RX drugiej płytki oraz
obie płytki muszą mieć wspólną masę.

### `rtl/comm/uart_byte_link.sv`

`uart_byte_link` jest adapterem pomiędzy kontrolerem pakietów gry a rdzeniem
UART z przykładowego projektu. Udostępnia prostszy interfejs bajtowy:

- `tx_ready`, informujące, że można podać kolejny bajt,
- `tx_valid`, zgłaszające ważny bajt do wysłania,
- `tx_data`, czyli bajt do wysłania,
- `rx_valid`, informujące o odebraniu bajtu,
- `rx_data`, czyli odebrany bajt.

Dzięki temu `pmod_comm_controller.sv` może operować na bajtach pakietu, bez
bezpośredniego zarządzania FIFO i wewnętrzną maszyną UART.

### `rtl/comm/uart/uart.v`

`uart.v` jest rdzeniem UART pochodzącym z przykładowego projektu. Łączy kilka
mniejszych bloków:

- licznik generujący tick baud rate,
- odbiornik UART,
- nadajnik UART,
- FIFO odbiorcze,
- FIFO nadawcze.

W tym projekcie rdzeń nie jest używany bezpośrednio przez logikę gry, tylko
przez `uart_byte_link.sv`.

### `rtl/comm/uart/uart_rx.v`

`uart_rx` odbiera pojedyncze bajty z linii UART. Rozpoznaje start bit, próbkuje
bity danych i czeka na stop bit. Moduł pracuje z tickiem oversamplingu
dostarczanym przez `uart.v`.

Jest to najniższy poziom odbioru UART w projekcie.

### `rtl/comm/uart/uart_tx.v`

`uart_tx` wysyła pojedyncze bajty przez UART. Dla każdego bajtu generuje start
bit, bity danych i stop bit.

Jest to najniższy poziom nadawania UART w projekcie.

### `rtl/comm/uart/fifo.v`

`fifo` jest prostą kolejką używaną przez rdzeń UART. Oddziela moment wpisania
bajtu do UART od momentu jego faktycznego wysłania albo odczytu.

W projekcie występuje jako:

- FIFO odbiorcze,
- FIFO nadawcze.

### `rtl/comm/uart/mod_m_counter.v`

`mod_m_counter` jest licznikiem modulo M. W rdzeniu UART służy do generowania
ticku baud rate, czyli impulsu wyznaczającego tempo próbkowania i wysyłania
bitów.

Jest to mały moduł pomocniczy, ale bez niego UART nie miałby stabilnego timingu.

## Moduły pomocnicze

### `rtl/common/reset_sync.sv`

`reset_sync` synchronizuje zwolnienie resetu aktywnego niskim stanem. Reset może
zostać aktywowany asynchronicznie, ale jego zwolnienie następuje synchronicznie
do danej domeny zegara.

W projekcie jest to ważne, ponieważ działają co najmniej dwie domeny zegarowe:

- 65 MHz dla VGA i większości logiki,
- 100 MHz dla kontrolera myszy i reset debounce.

Moduł zmniejsza ryzyko problemów przy wychodzeniu z resetu.

### `rtl/common/debounce.v`

`debounce` stabilizuje sygnał z przycisku mechanicznego. Przycisk może generować
krótkie drgania styków, więc bez debounce logika mogłaby zobaczyć kilka zmian
zamiast jednego naciśnięcia albo zwolnienia.

Moduł wystawia:

- `db_level`, czyli stabilny poziom sygnału,
- `db_tick`, czyli jednocykliczny impuls przy zaakceptowanej zmianie na stan
  wysoki.

W projekcie moduł jest używany przy obsłudze fizycznego resetu `btnC`.

### `rtl/common/delay.sv`

`delay` jest parametrycznym modułem opóźniającym sygnał o zadaną liczbę cykli.
Szerokość danych i liczba cykli opóźnienia są ustawiane parametrami.

Jest to moduł pomocniczy, który można wykorzystać tam, gdzie trzeba wyrównać
czasowo kilka sygnałów w potoku.

## Gdzie szukać konkretnych funkcji

- Zasady gry i przejścia między stanami: `rtl/game/game_core.sv`
- Lista stanów gry i typów pakietów: `rtl/game/guess_who_pkg.sv`
- Rozdzielczość, pozycja planszy, przyciski i panel: `rtl/vga/vga_pkg.sv`
- Generacja liczników VGA: `rtl/vga/vga_timing.sv`
- Tło i siatka planszy: `rtl/render/draw_bg.sv`
- Kolory przycisków i panelu: `rtl/render/ui_renderer.sv`
- Rysowanie postaci: `rtl/render/face_renderer.sv`
- Cechy postaci: `rtl/render/face_traits_rom.sv`
- Eliminacje, zaznaczenia i ramki: `rtl/render/board_renderer.sv`
- Napisy i komunikaty ekranowe: `rtl/text/text_renderer.sv`
- Font znaków: `rtl/text/font_rom.sv`
- Obsługa fizycznej myszy PS/2: `rtl/mouse/MouseCtl.vhd`
- Synchronizacja myszy i impulsy kliknięć: `rtl/mouse/mouse_adapter.sv`
- Hitboxy planszy i przycisków: `rtl/ui/hitbox_decoder.sv`
- Tryb kursora: `rtl/mouse/cursor_mode_controller.sv`
- Rysowanie kursora: `rtl/mouse/draw_mouse.sv`
- Komunikacja między płytkami: `rtl/comm/pmod_comm_controller.sv`
- Bajtowy interfejs UART: `rtl/comm/uart_byte_link.sv`
- Rdzeń UART: `rtl/comm/uart/uart.v`
- Reset i domeny zegarowe Basys 3: `fpga/rtl/top_basys3.sv`

## Podsumowanie architektury

Projekt jest rozdzielony na wyraźne warstwy. Logika gry znajduje się w
`game_core.sv`, komunikacja w `pmod_comm_controller.sv`, a obraz jest budowany
przez kolejne renderery VGA. Dzięki temu można analizować i rozwijać projekt
modułowo: zmiana wyglądu postaci nie wymaga zmian w UART, a zmiana protokołu
komunikacji nie wymaga modyfikowania rendererów.

Taki podział jest istotny w projekcie FPGA, ponieważ ułatwia testowanie,
utrzymanie kodu i wyjaśnienie działania układu podczas prezentacji na sprzęcie.
