# Instrukcja podłączenia sprzętu

Ten dokument opisuje wymagane połączenia sprzętowe dla projektu Guess Who
uruchamianego na dwóch płytkach Digilent Basys 3. Obie płytki powinny być
zaprogramowane tym samym bitstreamem.

## Wymagane elementy

- 2 płytki Digilent Basys 3,
- 2 przewody USB do programowania i zasilania płytek,
- 2 monitory VGA albo jeden monitor używany kolejno do testów,
- 2 przewody VGA,
- 2 myszy PS/2,
- przewody połączeniowe do złącza PMOD JA,
- wspólne połączenie masy między płytkami.

## Ustawienie identyfikatora gracza

Przed rozpoczęciem gry należy ustawić różne wartości przełącznika `SW[0]` na obu
płytkach:

| Płytka | Ustawienie `SW[0]` | Rola w logice tur |
| --- | ---: | --- |
| Płytka A | `0` | Rozpoczyna pierwszą turę |
| Płytka B | `1` | Czeka na pierwszą turę przeciwnika |

Obie płytki nie powinny mieć tej samej wartości `SW[0]`, ponieważ wtedy logika
ustalania pierwszej tury nie będzie odpowiadała rozgrywce dwuosobowej.

## Połączenie UART przez PMOD JA

Komunikacja między płytkami jest realizowana przez UART na złączu PMOD JA.

Aktualne użycie pinów:

| Pin PMOD | Funkcja w projekcie |
| --- | --- |
| `JA1` | Pomocnicze wyjście zegara pikselowego, nie jest wymagane do gry |
| `JA2` | UART TX |
| `JA3` | UART RX |
| `GND` | Wspólna masa |

Połączenia między płytkami należy wykonać krzyżowo:

| Płytka A | Płytka B |
| --- | --- |
| `JA2` TX | `JA3` RX |
| `JA3` RX | `JA2` TX |
| `GND` | `GND` |

Wspólna masa jest wymagana. Bez połączenia GND odbiór UART może być niestabilny
albo całkowicie błędny, nawet jeśli linie TX i RX są połączone poprawnie.

## Podłączenie VGA

Każda płytka generuje własny obraz VGA 1024 x 768.

Zalecane podłączenie:

- płytka A do pierwszego monitora VGA,
- płytka B do drugiego monitora VGA.

Jeżeli dostępny jest tylko jeden monitor, można sprawdzać płytki kolejno. Wtedy
należy pamiętać, że każda płytka pokazuje własny lokalny stan gry, w tym własną
sekretną postać i własne lokalne eliminacje.

## Podłączenie myszy PS/2

Do każdej płytki należy podłączyć osobną mysz PS/2 przez złącze PS/2 dostępne na
Basys 3.

Mysz służy do:

- wyboru tajnej postaci,
- kliknięcia `START`,
- lokalnej eliminacji postaci prawym przyciskiem,
- zgadywania postaci przeciwnika lewym przyciskiem,
- kliknięcia `KONIEC TURY`,
- kliknięcia `RESET GRY`.

## Reset

Fizyczny przycisk `BTNC` służy jako reset sprzętowy projektu.

Wewnętrzna logika projektu używa resetu aktywnego niskim stanem. Zwolnienie
resetu jest stabilizowane przez debounce i synchronizowane osobno dla domen
zegarowych 65 MHz oraz 100 MHz.

Reset warto nacisnąć:

- po zaprogramowaniu obu płytek,
- po zmianie ustawienia `SW[0]`,
- gdy jedna z płytek pozostaje w starym stanie gry,
- po ponownym podłączeniu przewodów PMOD.

## Kolejność uruchomienia

1. Podłączyć obie płytki Basys 3 do komputera przez USB.
2. Zaprogramować obie płytki tym samym bitstreamem.
3. Ustawić `SW[0] = 0` na pierwszej płytce.
4. Ustawić `SW[0] = 1` na drugiej płytce.
5. Podłączyć UART krzyżowo: `JA2` do `JA3`, `JA3` do `JA2`.
6. Połączyć masę `GND` między płytkami.
7. Podłączyć monitory VGA.
8. Podłączyć myszy PS/2.
9. Nacisnąć `BTNC` na obu płytkach.
10. Poczekać na pojawienie się obrazu i zestawienie linku.
11. Na obu płytkach wybrać tajną postać.
12. Na obu płytkach kliknąć `START`.

## Uwagi diagnostyczne

Jeżeli gra nie przechodzi dalej niż oczekiwanie na link, należy sprawdzić:

- czy `JA2` jednej płytki jest połączone z `JA3` drugiej płytki,
- czy `JA3` jednej płytki jest połączone z `JA2` drugiej płytki,
- czy płytki mają wspólną masę,
- czy obie płytki są zaprogramowane aktualnym bitstreamem,
- czy `SW[0]` ma różne wartości na obu płytkach,
- czy po zmianie przewodów wykonano reset `BTNC`.

Jeżeli obraz VGA działa, ale mysz nie reaguje, należy sprawdzić:

- czy mysz jest podłączona przed resetem albo czy po podłączeniu wykonano reset,
- czy używana mysz jest zgodna z PS/2,
- czy kursor jest widoczny na ekranie.

Jeżeli obie płytki działają osobno, ale rozgrywka nie synchronizuje tur, w
pierwszej kolejności należy sprawdzić połączenie UART i ustawienia `SW[0]`.

