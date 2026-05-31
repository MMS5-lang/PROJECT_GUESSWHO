# MTM / Basys 3 / SystemVerilog - zasady projektu, kodowania i modelowania

Ten plik jest praktycznym przewodnikiem dla osoby piszącej kod, osoby integrującej projekt oraz dla asystenta AI/Codexa pracującego w repozytorium. Zbiera wymagania z dokumentów projektowych, szablonów raportu, listy kontrolnej i wytycznych SystemVerilog.

> **Najważniejsza korekta dla tego projektu:** w projekcie stosujemy **reset asynchroniczny**, aktywny stanem niskim, o nazwie `rst_n`. Jeżeli którykolwiek dokument mówi o resecie synchronicznym, należy traktować to jako błąd względem aktualnych ustaleń projektu.

---

## 1. Najważniejsze zasady bezwzględne

1. Projekt jest pisany głównie w **SystemVerilog**.
2. Kod RTL musi być pisany zgodnie z regułami stylu opisanymi w tym pliku.
3. Projekt działa na **dwóch płytkach Basys 3**.
4. Projekt/gra musi mieć **interfejs użytkownika**: mysz, klawiaturę lub inne urządzenie zewnętrzne.
5. Wynik działania musi być wyświetlany na **VGA 1024 x 768 lub w rozdzielczości zbliżonej**. Nie używać 800 x 600 jako docelowej rozdzielczości.
6. W trybie gry multiplayer każdy gracz ma własną płytkę, własny ekran i własne urządzenie wejściowe.
7. Płytki muszą się komunikować między sobą.
8. W repozytorium nie wolno trzymać plików generowanych przez Vivado.
9. Repozytorium musi pozwalać na uruchomienie symulacji i wygenerowanie bitstreamu po sklonowaniu w nowym katalogu.
10. W katalogu `doc` muszą znaleźć się raport PDF i lista kontrolna PDF.
11. W katalogu `results` musi znaleźć się bitstream dla Basys 3.
12. Nie może być błędów Vivado ani nieuzasadnionych critical warnings.
13. Każdy moduł powinien mieć autora w nagłówku pliku.
14. Każdy plik RTL powinien zawierać jeden moduł/interfejs/klasę, a nazwa pliku powinna odpowiadać nazwie modułu.
15. Reset w tym projekcie: **asynchroniczny**, aktywny niskim poziomem, `rst_n`.

---

## 2. Reset - wersja obowiązująca w tym projekcie

### 2.1. Obowiązująca konwencja

W całym projekcie używamy:

```systemverilog
input logic clk,
input logic rst_n,
```

- `clk` - główny sygnał zegarowy, aktywny zboczem narastającym.
- `rst_n` - reset asynchroniczny, aktywny stanem niskim.
- Sufiks `_n` oznacza sygnał aktywny stanem niskim.

### 2.2. Wzorzec rejestru z resetem asynchronicznym

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        counter <= 32'h0;
    end else begin
        state <= state_nxt;
        counter <= counter_nxt;
    end
end
```

### 2.3. Czego nie robić

Nie używać resetu synchronicznego w modułach gry:

```systemverilog
/* NIE dla tego projektu */
always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= state_nxt;
    end
end
```

Nie inicjalizować rejestrów konstrukcją `initial` w kodzie syntezowalnym.

```systemverilog
/* NIE w RTL syntezowalnym */
initial begin
    state = IDLE;
end
```

### 2.4. Korekta względem checklisty i wymagań

Jeżeli formularz albo wymagania pytają:

```text
Czy układ używa resetu synchronicznego?
```

Dla tego projektu odpowiedź powinna być traktowana jako:

```text
NIE - projekt używa resetu asynchronicznego rst_n, zgodnie z aktualną korektą wymagań.
```

Dobrze jest dopisać w raporcie uwagę:

```text
W projekcie celowo zastosowano reset asynchroniczny aktywny stanem niskim (`rst_n`).
Jest to świadoma korekta względem starszej wersji wymagań/listy kontrolnej, w której pojawiał się reset synchroniczny.
```

---

## 3. Struktura repozytorium

Zalecana struktura repozytorium:

```text
project_name/
├── doc/
│   ├── checklist.pdf
│   ├── report.pdf
│   ├── project_spec.md
│   └── ...
├── fpga/
│   ├── constraints/
│   ├── ip/
│   ├── rtl/
│   └── scripts/
├── results/
│   └── project_name.bit
├── rtl/
│   ├── common/
│   ├── game/
│   ├── vga/
│   ├── input/
│   ├── comm/
│   └── ...
├── sim/
│   ├── common/
│   ├── top_fpga/
│   ├── top_rtl/
│   └── ...
├── tools/
├── README.md
└── .gitignore
```

Uwagi:

- `doc` zawiera dokumentację, raport, checklistę i dodatkowe pliki opisowe.
- `results` zawiera końcowy bitstream.
- `rtl` zawiera pliki syntezowalne.
- `sim` zawiera testbenche i pliki symulacyjne.
- `fpga/constraints` zawiera pliki ograniczeń, np. `.xdc`.
- `fpga/ip` zawiera IP cores, jeżeli są potrzebne i da się je sensownie odtworzyć.
- Moduły w `rtl` należy grupować w podkatalogach tematycznych.
- Nie trzymać w git plików tymczasowych i generowanych przez Vivado.

---

## 4. Git i praca zespołowa

1. Projekt musi być prowadzony w systemie kontroli wersji Git.
2. Użycie Gita ma być realne w czasie projektu, a nie jednorazowe wrzucenie końcowej wersji.
3. Każdy członek zespołu powinien mieć wkład w historii repozytorium.
4. Warto używać branchy, np.:

```text
main
feature/vga-renderer
feature/game-core
feature/pmod-comm
feature/mouse-input
fix/reset-handling
```

5. Repozytorium prywatne powinno mieć dodanego prowadzącego, jeżeli jest to wymagane.
6. Przed oddaniem trzeba sklonować repozytorium do pustego katalogu i sprawdzić, czy da się:
   - uruchomić symulację,
   - wygenerować bitstream,
   - znaleźć raport PDF,
   - znaleźć checklistę PDF,
   - znaleźć bitstream w `results`.

### 4.1. Pliki, których nie wrzucać do repozytorium

Nie commitować:

```text
*.jou
*.log
*.str
*.wdb
*.pb
*.cache/
*.hw/
*.ip_user_files/
*.runs/
*.sim/
*.xpr-generated-backups/
vivado*.backup*
.DS_Store
Thumbs.db
```

Dopuszczalne są tylko pliki źródłowe, ograniczenia, skrypty, dokumentacja i rzeczy wymagane do odtworzenia projektu.

---

## 5. Architektura projektu

### 5.1. Moduły strukturalne i funkcjonalne

Dobry projekt rozdziela moduły na:

- **strukturalne** - składają inne moduły, prawie nie mają logiki proceduralnej,
- **funkcjonalne** - zawierają właściwą logikę w blokach `always_ff` / `always_comb`.

Nie mieszać tych stylów bez potrzeby.

Przykład:

- `top_guess_who.sv` - moduł strukturalny,
- `game_core.sv` - moduł funkcjonalny,
- `hitbox_decoder.sv` - moduł funkcjonalny/kombinacyjny,
- `board_renderer.sv` - moduł renderujący,
- `pmod_comm_controller.sv` - moduł komunikacji.

### 5.2. Moduł `top`

Moduł główny powinien:

1. Przyjmować sygnały z płytki Basys 3.
2. Zawierać generator zegara lub instancję IP clock wizarda.
3. Łączyć moduły VGA, myszy, logiki gry, komunikacji i renderowania.
4. Być możliwie strukturalny.
5. Nie zawierać rozbudowanej logiki FSM, jeżeli można ją przenieść do osobnych modułów.

### 5.3. Schemat blokowy

Schemat blokowy w raporcie nie jest schematem z Vivado. Ma pokazywać:

- moduły składowe,
- interfejsy między modułami,
- przepływ danych,
- główne bloki funkcjonalne.

Na schemacie blokowym:

- nie trzeba pokazywać każdego pojedynczego sygnału,
- interfejs oznacza grupę sygnałów,
- interfejsy dwukierunkowe należy rozbić na dwa jednokierunkowe,
- nazwa interfejsu powinna być prefiksem sygnałów składowych,
- nie uwzględnia się sygnałów globalnych typu `clk` i `rst_n`.

Przykład interfejsu:

```text
m2c - mouse to core
m2c_x[10:0]
m2c_y[10:0]
m2c_left_click
m2c_right_click
m2c_valid
```

---

## 6. Zegary i domeny zegarowe

1. Główny zegar z płytki Basys 3 trafia do modułu głównego.
2. Generator zegara / Clocking Wizard powinien być umieszczony w module głównym.
3. Pozostałe moduły używają wyłącznie zegarów wygenerowanych w module głównym.
4. Jeżeli używane są różne częstotliwości, powinny być dobrane tak, aby można było wygenerować je z jednego IP generatora zegara.
5. Dla VGA 1024 x 768 typowo potrzebny jest zegar pikselowy około 65 MHz.
6. Unikać tworzenia nowych zegarów zwykłą logiką RTL.
7. Do spowalniania logiki preferować **clock enable**, a nie dzielony zegar.
8. Jeżeli sygnał przechodzi między domenami zegarowymi, trzeba użyć synchronizacji.
9. Sygnały z myszy/PS2 muszą zostać zsynchronizowane do domeny logiki gry.

### 6.1. Clock enable zamiast dzielonego zegara

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_counter <= 32'h0;
        slow_tick <= 1'b0;
    end else begin
        slow_tick <= 1'b0;

        if (tick_counter == TICK_DIVIDER - 1) begin
            tick_counter <= 32'h0;
            slow_tick <= 1'b1;
        end else begin
            tick_counter <= tick_counter + 32'h1;
        end
    end
end
```

---

## 7. Formatowanie kodu SystemVerilog

### 7.1. Długość linii

Maksymalna długość linii: **120 znaków**.

### 7.2. Wcięcia

Każdy poziom zagnieżdżenia: **4 spacje**.

Instrukcje pierwszego poziomu wewnątrz `module`, `interface`, `package` itp. nie powinny mieć dodatkowego wcięcia.

### 7.3. Puste linie i spacje

- Na końcu pliku zostawić jedną pustą linię.
- Nie zostawiać spacji na końcu linii.
- W jednej linii powinno być jedno wyrażenie.

Źle:

```systemverilog
valid = 1'b1; data = 32'h0;
```

Dobrze:

```systemverilog
valid = 1'b1;
data = 32'h0;
```

### 7.4. Spacje przy operatorach i nawiasach

Dobrze:

```systemverilog
if (a == b) begin
    y = a + b;
end
```

Źle:

```systemverilog
if ( a==b ) begin
    y=a+b;
end
```

Zasady:

- Po słowie kluczowym dawać spację przed nawiasem: `if (condition)`.
- Nie dawać spacji wewnątrz nawiasów: `(a == b)`, nie `( a == b )`.
- Dawać spacje wokół operatorów: `a + b`, `a == b`, `a && b`.
- Po przecinku i średniku wewnątrz wyrażeń dawać pojedynczą spację.

---

## 8. Struktura bloków

### 8.1. `begin` / `end`

Używać `begin` / `end` nawet dla pojedynczej instrukcji.

```systemverilog
if (valid) begin
    counter_nxt = counter + 32'h1;
end
```

### 8.2. `if` / `else`

`else` powinien być w tej samej linii co `end` poprzedniej gałęzi.

```systemverilog
if (rvalid) begin
    dvalid_nxt = 1'b1;
    dout_nxt = rdata;
end else begin
    dvalid_nxt = 1'b0;
    dout_nxt = 32'h0;
end
```

### 8.3. `case`

Etykiety w `case` powinny być wcięte o jeden poziom względem `case`.

```systemverilog
case (state)
    S_IDLE: begin
        if (start) begin
            state_nxt = S_ACTIVE;
        end
    end

    S_ACTIVE: begin
        if (done) begin
            state_nxt = S_IDLE;
        end
    end

    default: begin
        state_nxt = S_IDLE;
    end
endcase
```

W blokach kombinacyjnych `default` jest obowiązkowy, chyba że wcześniej wykonano kompletne przypisania domyślne.

---

## 9. Kolejność sekcji w module

Zalecana kolejność:

1. Importy pakietów.
2. Parametry modułu.
3. Porty modułu.
4. Parametry lokalne.
5. Definicje typów.
6. Definicje sygnałów lokalnych.
7. Przypisania `assign`.
8. Instancje podmodułów.
9. Bloki `always_ff` / `always_comb`.

Przykład szkieletu:

```systemverilog
module example_module
import project_pkg::*;
#(
    parameter int DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,
    output logic valid,
    output logic [DATA_WIDTH-1:0] data,
    input  logic start
);

localparam int COUNTER_WIDTH = 16;

typedef enum logic [1:0] {
    S_IDLE,
    S_BUSY,
    S_DONE
} state_t;

state_t state, state_nxt;
logic [COUNTER_WIDTH-1:0] counter, counter_nxt;

assign valid = (state == S_DONE);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        counter <= '0;
    end else begin
        state <= state_nxt;
        counter <= counter_nxt;
    end
end

always_comb begin
    state_nxt = state;
    counter_nxt = counter;

    case (state)
        S_IDLE: begin
            if (start) begin
                state_nxt = S_BUSY;
                counter_nxt = '0;
            end
        end

        S_BUSY: begin
            counter_nxt = counter + {{COUNTER_WIDTH-1{1'b0}}, 1'b1};
            if (counter == 16'd1000) begin
                state_nxt = S_DONE;
            end
        end

        S_DONE: begin
            state_nxt = S_IDLE;
        end

        default: begin
            state_nxt = S_IDLE;
            counter_nxt = '0;
        end
    endcase
end

endmodule
```

---

## 10. Konstrukcje sekwencyjne i kombinacyjne

### 10.1. Używać specjalizowanych bloków

W kodzie RTL używać:

```systemverilog
always_ff
always_comb
always_latch
```

Nie używać generycznego `always` w RTL syntezowalnym. `always` jest dopuszczalne w testbenchach.

### 10.2. Przypisania

W blokach sekwencyjnych:

```systemverilog
q <= d;
```

W blokach kombinacyjnych:

```systemverilog
y = a & b;
```

Nie mieszać przypisań blokujących i nieblokujących w tym samym typie logiki bez bardzo mocnego powodu.

### 10.3. Unikanie latchy

Każdy sygnał ustawiany w `always_comb` musi dostać wartość w każdej ścieżce wykonania.

Wzorzec:

```systemverilog
always_comb begin
    out_nxt = out;
    valid_nxt = 1'b0;

    if (condition) begin
        out_nxt = input_data;
        valid_nxt = 1'b1;
    end
end
```

---

## 11. Nazewnictwo

### 11.1. Notacja

Używać `snake_case`.

Dobrze:

```systemverilog
logic [7:0] bytes_counter;
module edge_detector (...);
```

Źle:

```systemverilog
logic [7:0] bytesCounter;
module EdgeDetector (...);
```

### 11.2. Wielkość liter

- Nazwy modułów, sygnałów, portów: małe litery.
- Nazwy stałych i parametrów: wielkie litery.
- Nazwy typów: małe litery z sufiksem `_t`.

```systemverilog
const int BITS_IN_BYTE = 8;
logic [BITS_IN_BYTE-1:0] received_byte;

typedef enum logic [1:0] {
    S_IDLE,
    S_BUSY
} state_t;
```

### 11.3. Sufiksy

- `_nxt` - wartość wyznaczona kombinacyjnie na następny takt.
- `_n` - sygnał aktywny stanem niskim.
- `_t` - typ, struktura lub enum.
- `u_...` - instancja modułu.
- `tb_...` - testbench.
- `dut` - testowany moduł w testbenchu.

---

## 12. Literały i liczby

Każdy literał liczbowy powinien mieć określoną szerokość.

Dobrze:

```systemverilog
counter = 32'h0;
mask = 18'h0;
value = 8'd255;
```

Źle:

```systemverilog
counter = 0;
mask = 'h0;
```

Dla długich liczb używać separatorów:

```systemverilog
localparam int CLK_FREQ_HZ = 100_000_000;
localparam int PIXEL_CLK_HZ = 65_000_000;
```

---

## 13. Moduły, porty, parametry i instancje

### 13.1. Jeden port w jednej linii

```systemverilog
module hitbox_decoder (
    input  logic clk,
    input  logic rst_n,
    output logic hit_valid,
    output logic [4:0] hit_id,
    input  logic [10:0] mouse_x,
    input  logic [10:0] mouse_y,
    input  logic click
);
```

### 13.2. Kolejność portów

Zalecana kolejność:

1. Zegar.
2. Reset.
3. Wyjścia.
4. Wejścia.

### 13.3. Parametry

Parametry pisać wielkimi literami:

```systemverilog
parameter int BOARD_COLS = 6,
parameter int BOARD_ROWS = 3,
parameter int N_CHARACTERS = BOARD_COLS * BOARD_ROWS
```

### 13.4. Instancje

Używać nazwanych połączeń.

```systemverilog
hitbox_decoder u_hitbox_decoder (
    .clk,
    .rst_n,
    .hit_valid,
    .hit_id,
    .mouse_x(m2c_x),
    .mouse_y(m2c_y),
    .click(m2c_left_click)
);
```

Nie używać połączeń pozycyjnych:

```systemverilog
/* NIE */
hitbox_decoder u_hitbox_decoder (clk, rst_n, hit_valid, hit_id, mouse_x, mouse_y, click);
```

---

## 14. Pakiety i importy

Wspólne stałe, typy, kolory, rozmiary planszy, typy pakietów komunikacji i stany FSM umieszczać w pakietach.

Przykład:

```systemverilog
package guess_who_pkg;

localparam int BOARD_COLS = 6;
localparam int BOARD_ROWS = 3;
localparam int N_CHARACTERS = BOARD_COLS * BOARD_ROWS;
localparam int CHARACTER_ID_WIDTH = 5;

typedef enum logic [3:0] {
    S_RESET,
    S_SELECT_SECRET,
    S_LOCAL_READY,
    S_MY_TURN,
    S_OPPONENT_TURN,
    S_WAIT_RESULT,
    S_WIN,
    S_LOSE
} game_state_t;

typedef enum logic [3:0] {
    PKT_HELLO,
    PKT_READY,
    PKT_TURN_END,
    PKT_GUESS,
    PKT_FINAL_CHECK,
    PKT_RESULT_CORRECT,
    PKT_RESULT_WRONG,
    PKT_RESET_GAME
} packet_type_t;

endpackage
```

Import pakietu umieszczać między nazwą modułu a listą portów:

```systemverilog
module game_core
import guess_who_pkg::*;
(
    input logic clk,
    input logic rst_n
);
```

---

## 15. Komentarze i dokumentacja w kodzie

Komentarze mają tłumaczyć rzeczy nieoczywiste, a nie powtarzać dokładnie to, co robi kod.

Preferować komentarze blokowe:

```systemverilog
/* Synchronizacja sygnału z domeny PS/2 do domeny logiki gry. */
```

Komentarz wielowierszowy:

```systemverilog
/**
 * Ten moduł dekoduje kliknięcia myszy na identyfikatory pól planszy.
 * Nie przechowuje bitmap ani stanu gry.
 */
```

Każdy plik powinien mieć nagłówek z autorem:

```systemverilog
/*
 * Project: Guess Who on Basys 3
 * File: game_core.sv
 * Author: Imie Nazwisko
 * Description: Main game finite state machine.
 */
```

Jeżeli używany jest zewnętrzny moduł, w nagłówku pliku dodać źródło/link i informację o licencji.

---

## 16. Maszyny stanów skończonych FSM

### 16.1. Definicja stanów

Stany definiować jako `typedef enum logic`.

```systemverilog
typedef enum logic [2:0] {
    S_IDLE,
    S_SELECT,
    S_READY,
    S_PLAY,
    S_WIN,
    S_LOSE
} state_t;

state_t state, state_nxt;
```

### 16.2. Rozdział logiki

FSM powinna mieć:

- blok sekwencyjny do rejestracji aktualnego stanu,
- blok kombinacyjny do wyznaczania następnego stanu i sygnałów `_nxt`.

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
    end else begin
        state <= state_nxt;
    end
end

always_comb begin
    state_nxt = state;

    case (state)
        S_IDLE: begin
            if (start) begin
                state_nxt = S_SELECT;
            end
        end

        S_SELECT: begin
            if (ready) begin
                state_nxt = S_READY;
            end
        end

        default: begin
            state_nxt = S_IDLE;
        end
    endcase
end
```

### 16.3. Zasady FSM

1. Stan aktualny: `state`.
2. Stan następny: `state_nxt`.
3. Typ stanu: `state_t`.
4. Każdy stan powinien mieć jasną odpowiedzialność.
5. Nie robić zbyt dużych FSM, jeżeli można rozbić logikę na mniejsze moduły.
6. W `always_comb` najpierw ustawić wartości domyślne.
7. Każdy `case` powinien obsługiwać `default`.
8. Reset ustawia FSM w stan startowy.

---

## 17. Testbenche i symulacja

### 17.1. Nazewnictwo

- Testbench modułu `game_core` powinien nazywać się `tb_game_core`.
- Testowany moduł zawsze nazywać `dut`.

```systemverilog
game_core dut (
    .clk,
    .rst_n,
    .win,
    .lose,
    .start
);
```

### 17.2. Generowanie zegara w testbenchu

W testbenchach można używać `initial` i `always`.

```systemverilog
initial begin
    clk = 1'b0;
    forever begin
        #5ns;
        clk = ~clk;
    end
end
```

### 17.3. Reset w testbenchu

Dla resetu asynchronicznego:

```systemverilog
task reset_dut();
    rst_n = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    repeat (1) @(negedge clk);
endtask
```

### 17.4. Asercje

Sprawdzać wyniki asercjami:

```systemverilog
assert (state_dbg == S_MY_TURN) else begin
    $error("Expected S_MY_TURN, got %0d", state_dbg);
end
```

### 17.5. Minimalny zestaw testów

Dla każdego ważnego modułu przygotować przynajmniej prosty test:

- `hitbox_decoder` - kliknięcia w pola i poza pola.
- `game_core` - wybór postaci, start, tury, poprawny i błędny strzał, reset.
- `pmod_comm_controller` - kodowanie/dekodowanie pakietów, błędny checksum/parity, reset.
- `board_renderer` - sprawdzenie priorytetów kolorów/stanu pól w prostych punktach pikseli.
- `mouse_adapter` - generowanie impulsów kliknięć.

---

## 18. Typowe wzorce RTL

### 18.1. Moduł kombinacyjny

```systemverilog
module and2 (
    output logic y,
    input  logic a,
    input  logic b
);

assign y = a & b;

endmodule
```

### 18.2. Detektor zbocza narastającego

```systemverilog
module rising_edge_detector (
    input  logic clk,
    input  logic rst_n,
    output logic edge_detected,
    input  logic din
);

logic din_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_q <= 1'b0;
    end else begin
        din_q <= din;
    end
end

always_comb begin
    edge_detected = din & ~din_q;
end

endmodule
```

### 18.3. Rejestr przesuwający

```systemverilog
module shift_register #(
    parameter int WIDTH = 4
)(
    input  logic clk,
    input  logic rst_n,
    output logic dout,
    input  logic din
);

logic [WIDTH-1:0] data;

assign dout = data[0];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= '0;
    end else begin
        data <= {din, data[WIDTH-1:1]};
    end
end

endmodule
```

### 18.4. Licznik

```systemverilog
module counter #(
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    output logic [WIDTH-1:0] count,
    input  logic enable
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= '0;
    end else if (enable) begin
        count <= count + {{WIDTH-1{1'b0}}, 1'b1};
    end
end

endmodule
```

### 18.5. RAM z synchronicznym odczytem

```systemverilog
module simple_ram #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    output logic [DATA_WIDTH-1:0] rdata,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic write_enable
);

logic [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= '0;
    end else begin
        if (write_enable) begin
            mem[addr] <= wdata;
        end
        rdata <= mem[addr];
    end
end

endmodule
```

Uwaga: zawartości dużej pamięci zwykle nie resetuje się w jednym takcie, jeżeli ma być inferowana jako RAM blokowy. Resetować można rejestry wyjściowe i sterujące.

---

## 19. Wymagania implementacyjne Vivado

W raporcie trzeba uwzględnić:

1. Listę zignorowanych ostrzeżeń Vivado.
2. Wykorzystanie zasobów.
3. Marginesy czasowe.
4. Konfigurację sprzętu.

### 19.1. Lista ostrzeżeń

Każde zignorowane ostrzeżenie musi mieć uzasadnienie.

| Identyfikator ostrzeżenia | Liczba wystąpień | Uzasadnienie |
|---|---:|---|
| TODO | TODO | TODO |

Nie wolno zostawiać nieuzasadnionych critical warnings.

### 19.2. Wykorzystanie zasobów

Wstawić tabelę z Vivado, np.:

| Zasób | Wykorzystane | Dostępne | Procent |
|---|---:|---:|---:|
| LUT | TODO | TODO | TODO |
| FF | TODO | TODO | TODO |
| BRAM | TODO | TODO | TODO |
| DSP | TODO | TODO | TODO |
| IO | TODO | TODO | TODO |
| BUFG | TODO | TODO | TODO |

Zasoby mają być używane sensownie. Nie używać DSP, BRAM, BUFG ani innych zasobów globalnych tam, gdzie nie są potrzebne.

### 19.3. Timing

W raporcie wpisać marginesy czasowe:

| Typ analizy | WNS | Status |
|---|---:|---|
| Setup | TODO | TODO |
| Hold | TODO | TODO |

Projekt powinien mieć poprawne timingi setup i hold.

---

## 20. Raport końcowy

Raport musi być oddany jako **PDF** w katalogu `doc`.

### 20.1. Sekcje raportu

Raport powinien zawierać:

1. **Repozytorium git**
   - adres repozytorium,
   - informacja o dostępie, jeżeli repo prywatne.

2. **Wstęp**
   - skąd pomysł,
   - co robi projekt,
   - krótki opis celu.

3. **Specyfikacja**
   - opis ogólny algorytmu,
   - co dzieje się po starcie,
   - przebieg działania,
   - warunki końca,
   - przykładowe zrzuty/szkice ekranu.

4. **Tabela zdarzeń**
   - zdarzenia zewnętrzne, np. kliknięcia użytkownika,
   - zdarzenia wewnętrzne, np. przejście FSM,
   - kategoria/stany,
   - reakcja systemu.

5. **Architektura**
   - opis modułu `top`,
   - schemat blokowy,
   - porty,
   - interfejsy,
   - rozprowadzenie zegara.

6. **Implementacja**
   - zignorowane ostrzeżenia Vivado,
   - wykorzystanie zasobów,
   - marginesy czasowe.

7. **Konfiguracja sprzętu**
   - schemat połączenia dwóch płytek Basys 3,
   - podłączenie VGA, myszy, PMOD itp.,
   - konfiguracja zworek/przełączników, jeśli inna niż domyślna.

8. **Film**
   - link do filmu demonstracyjnego.

### 20.2. Tabela zdarzeń - szablon

| Zdarzenie | Kategoria/stan | Reakcja systemu |
|---|---|---|
| LPM na postaci przed START | Wybór postaci | Ustawia tymczasowy wybór i pokazuje ramkę/panel. |
| START | Wybór postaci | Zatwierdza sekretną postać i wysyła READY. |
| READY z drugiej płytki | Oczekiwanie | Uruchamia grę, jeżeli lokalny gracz też jest gotowy. |
| PPM na postaci | Moja tura | Eliminuje postać lokalnie. |
| LPM na postaci po starcie | Moja tura | Wysyła zgadywanie do drugiej płytki. |
| RESET | Dowolny stan | Resetuje logikę gry na obu płytkach. |

---

## 21. Lista kontrolna przed oddaniem

Wypełnić checklistę i zapisać jako PDF w `doc/checklist.pdf`.

### 21.1. Pytania z checklisty

| Pytanie | Oczekiwana odpowiedź dla tego projektu |
|---|---|
| Czy raport został załączony w formacie PDF? | TAK |
| Czy w katalogu `results` został umieszczony bitstream? | TAK |
| Czy rozmieszczenie plików w katalogach projektu jest zgodne ze specyfikacją? | TAK |
| Czy repozytorium sprawdzono przez sklonowanie, symulację i wygenerowanie bitstreamu? | TAK |
| Numer użytej wersji Vivado | Wpisać konkretną wersję. |
| Liczba błędów Vivado | 0 |
| Liczba critical warnings Vivado | 0 |
| Liczba warnings Vivado | Wpisać liczbę i uzasadnić w raporcie. |
| Interfejs dostarczania danych przez użytkownika | Mysz / klawiatura / inne, zgodnie z projektem. |
| Użycie ekranu jako wyjścia | TAK |
| Rozdzielczość ekranu | 1024 x 768 lub zbliżona. |
| Czy układ używa resetu synchronicznego? | NIE - korekta: używamy resetu asynchronicznego `rst_n`. |
| Czy układ używa resetu asynchronicznego? | TAK - dopisać, jeżeli trzeba wyjaśnić korektę. |
| Identyfikator przycisku Basys 3 użytego jako reset | Wpisać, np. BTNC/BTND, zgodnie z `.xdc`. |
| Czy moduły używają wyłącznie zegarów generowanych przez IP generatora zegara? | TAK, jeżeli dotyczy. |

Jeżeli pojawią się nieuzasadnione błędy lub critical warnings, projekt może zostać oceniony negatywnie.

---

## 22. Film demonstracyjny

Film powinien:

1. Być krótki, około 1-2 minuty.
2. Pokazywać działanie najważniejszych funkcji.
3. Zawierać odniesienie do kierunku MTM i strony `mtm.agh.edu.pl`, jeżeli jest to wymagane.
4. Mieć link umieszczony w raporcie.
5. Pokazać projekt na dwóch płytkach, jeśli projekt wymaga multiplayer.
6. Pokazać ekran VGA i interakcję użytkownika.
7. Pokazać reset, start gry, podstawową mechanikę i zakończenie.

---

## 23. Zewnętrzne moduły i cudzy kod

Można używać modułów zewnętrznych, jeżeli:

1. Są poprawnie zakodowane.
2. Pasują do stylu projektu lub są odizolowane wrapperem.
3. Ich źródło jest jasno opisane w nagłówku pliku.
4. Licencja pozwala na użycie.
5. Raport wspomina, które części pochodzą z zewnętrznych źródeł.

Nagłówek przykładowy:

```systemverilog
/*
 * File: ps2_interface_wrapper.sv
 * Author: Imie Nazwisko
 * External source: <link>
 * License: <license>
 * Notes: Wrapped and synchronized to local clk/rst_n convention.
 */
```

---

## 24. Wskazówki dla projektu Basys 3 / VGA / mysz / komunikacja

1. Najpierw uruchomić VGA i mysz na jednej płytce.
2. Następnie dodać statyczny ekran.
3. Potem dodać hitboxy i mapowanie kliknięć.
4. Dopiero potem dodawać pełną logikę gry.
5. Komunikację między płytkami testować najpierw osobno, np. loopbackiem albo prostym wysłaniem pakietu.
6. Nie zaczynać od ozdobnej grafiki.
7. Najpierw doprowadzić do działania wersję minimalną.
8. Dopiero później poprawiać wygląd, teksty i animacje.

### 24.1. VGA

- Docelowo 1024 x 768 lub rozdzielczość bardzo zbliżona.
- Zegar pikselowy około 65 MHz dla typowego 1024 x 768.
- Moduł VGA powinien generować `hcount`, `vcount`, `hsync`, `vsync`, `blanking` i opcjonalnie `frame_tick`.
- Renderery powinny działać na aktualnych współrzędnych piksela, a nie przechowywać całego ekranu.

### 24.2. Mysz / wejście

- Sygnały z PS/2 zsynchronizować do domeny zegara logiki.
- Kliknięcia powinny być impulsami jednotaktowymi: `left_click_pulse`, `right_click_pulse`.
- Pozycję myszy ograniczyć do obszaru ekranu.

### 24.3. Komunikacja dwóch płytek

- Protokół powinien być prosty i debugowalny.
- Warto mieć typ pakietu, payload, numer sekwencyjny i opcjonalną sumę kontrolną/parity.
- Komunikacja powinna obsługiwać reset, gotowość, tury i wyniki zgadywania.
- Nie synchronizować lokalnych danych, których drugi gracz nie musi znać.

---

## 25. Zasady dla Codexa / asystenta AI generującego kod

Jeżeli AI generuje lub modyfikuje kod w tym projekcie, musi przestrzegać poniższych reguł:

1. Nie zmieniać resetu na synchroniczny.
2. W każdym module RTL używać `clk` i `rst_n`.
3. Dla rejestrów używać `always_ff @(posedge clk or negedge rst_n)`.
4. W logice kombinacyjnej używać `always_comb`.
5. Nie używać `always` w RTL syntezowalnym.
6. Nie używać `initial` w RTL syntezowalnym.
7. Używać `logic`, nie starego stylu `reg`, chyba że istnieje uzasadnienie.
8. Stosować `snake_case`.
9. Parametry i stałe pisać wielkimi literami.
10. Używać sufiksów `_nxt`, `_n`, `_t`.
11. Jeden moduł na jeden plik.
12. Nazwa pliku taka sama jak nazwa modułu.
13. Instancje podłączać przez nazwy portów.
14. Testowany moduł w testbenchach nazywać `dut`.
15. Nie dodawać plików generowanych przez Vivado.
16. Jeżeli dodawany jest zewnętrzny kod, dodać link/licencję w nagłówku.
17. Utrzymać podział na moduły strukturalne i funkcjonalne.
18. Nie wkładać całej gry do `top`.
19. Nie tworzyć nowych zegarów zwykłą logiką; preferować clock enable.
20. Nie zakładać, że kliknięcie myszy trwa jeden takt - trzeba wygenerować impuls.
21. Nie przechowywać całych ramek VGA w pamięci, jeśli wystarczy renderer proceduralny.
22. Nie zostawiać magicznych liczb - przenieść je do parametrów/pakietów.
23. Każdy większy moduł powinien mieć testbench lub przynajmniej plan testów.

---

## 26. Typowe błędy do unikania

1. Reset synchroniczny mimo ustalonego resetu asynchronicznego.
2. Brak resetu dla rejestrów sterujących.
3. `always @(*)` zamiast `always_comb`.
4. `always @(posedge clk)` zamiast `always_ff`.
5. Przypisania `=` w bloku sekwencyjnym.
6. Przypisania `<=` w bloku kombinacyjnym.
7. Brak wartości domyślnych w `always_comb`.
8. Niepełny `case` bez `default`.
9. Mieszanie logiki strukturalnej i FSM w module `top`.
10. Zbyt duży moduł, którego nie da się testować.
11. Brak synchronizacji sygnałów z innej domeny zegarowej.
12. Commitowanie katalogów `.runs`, `.sim`, `.cache`, `.hw`.
13. Brak raportu PDF lub checklisty PDF.
14. Brak bitstreamu w `results`.
15. Brak uzasadnienia ostrzeżeń Vivado.
16. Użycie 800 x 600 jako docelowej rozdzielczości.
17. Brak rzeczywistego użycia Gita.
18. Brak informacji o autorach modułów.
19. Brak źródła zewnętrznych modułów.
20. Brak filmu lub linku w raporcie.

---

## 27. Minimalna procedura przed oddaniem

1. Sklonować repozytorium do nowego katalogu.
2. Uruchomić symulacje.
3. Otworzyć projekt/skrypty w Vivado.
4. Wygenerować bitstream.
5. Sprawdzić, że liczba błędów = 0.
6. Sprawdzić, że liczba critical warnings = 0 albo że są w pełni uzasadnione; najlepiej 0.
7. Sprawdzić setup WNS i hold WNS.
8. Sprawdzić wykorzystanie zasobów.
9. Zaprogramować Basys 3.
10. Sprawdzić działanie na sprzęcie.
11. Nagrać film.
12. Wygenerować raport PDF.
13. Wypełnić checklistę PDF.
14. Umieścić bitstream w `results`.
15. Sprawdzić finalną strukturę katalogów.
16. Zrobić finalny commit i push.

---

## 28. Ocena projektu - co jest punktowane

Elementy oceny wynikające z dokumentów projektowych:

1. Poprawność raportu finalnego i bazy projektu.
2. Zgodność z wymaganiami.
3. Jednolity i poprawny styl kodowania.
4. Autorzy oznaczeni w nagłówkach modułów.
5. Hierarchia projektu zgodna z dokumentacją.
6. Brak błędów i critical warnings.
7. Poprawne parametry czasowe setup i hold.
8. Sensowne wykorzystanie zasobów.
9. Rzeczywiste użycie Gita przez zespół.
10. Użycie branchy.
11. Repozytorium bez plików generowanych.
12. Poprawność działania programu zgodnie ze specyfikacją.
13. Stopień trudności i atrakcyjność projektu.
14. Jakość filmu/prezentacji.
15. Możliwy bonus za oddanie w pierwszym terminie, jeżeli projekt spełnia warunki bonusu.

---

## 29. Notatka o MicroBlaze

Jeżeli projekt korzysta z MicroBlaze, należy dodatkowo znać:

1. Vivado IP Integrator.
2. AXI Lite.
3. Budowę klienta AXI Lite slave.
4. Debugowanie AXI przez Vivado IP Integrator.
5. Integrated Logic Analyzer, czyli ILA.

Dla projektu bez MicroBlaze te materiały są pomocnicze, ale nadal przydatne przy pracy z IP Integratorem i debugowaniem.

---

## 30. Krótka lista kontrolna dla kodu RTL

Przed zaakceptowaniem pliku RTL sprawdź:

```text
[ ] Jeden moduł na plik.
[ ] Nazwa pliku odpowiada nazwie modułu.
[ ] Jest nagłówek z autorem.
[ ] Porty są w kolejności: clk, rst_n, outputy, inputy.
[ ] Reset to rst_n, asynchroniczny, aktywny nisko.
[ ] Rejestry w always_ff.
[ ] Kombinacja w always_comb.
[ ] Brak initial w RTL.
[ ] Brak always w RTL.
[ ] Przypisania <= w sekwencji.
[ ] Przypisania = w kombinacji.
[ ] Brak latchy.
[ ] Nazwy snake_case.
[ ] Stałe i parametry wielkimi literami.
[ ] Literały mają szerokości.
[ ] Instancje mają połączenia nazwane.
[ ] Brak magicznych liczb.
[ ] Sygnały z innej domeny są synchronizowane.
[ ] Moduł da się przetestować.
```

---

## 31. Krótka lista kontrolna dla repozytorium

```text
[ ] doc/report.pdf istnieje.
[ ] doc/checklist.pdf istnieje.
[ ] results/project_name.bit istnieje.
[ ] README.md opisuje projekt.
[ ] .gitignore usuwa pliki Vivado.
[ ] rtl/ zawiera źródła syntezowalne.
[ ] sim/ zawiera testbenche.
[ ] fpga/constraints/ zawiera XDC.
[ ] Nie ma katalogów generowanych przez Vivado.
[ ] Repo da się sklonować i zbudować od zera.
[ ] Historia Gita pokazuje realną pracę.
```

---

## 32. Najważniejsze ustalenie końcowe

W tym projekcie obowiązuje:

```text
Reset asynchroniczny, aktywny stanem niskim, nazwa rst_n.
```

Ta reguła ma pierwszeństwo przed starszymi fragmentami dokumentów mówiącymi o resecie synchronicznym.
