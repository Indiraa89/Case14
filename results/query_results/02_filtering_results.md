# 02_filtering.sql: орындау нәтижелері

Сүзу сұраныстары. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q2.1. AND: «барлығы қосылған» тамақтануы бар 5 жұлдызды қонақүйлер

```sql
SELECT hotel_name, board_type, price_per_night
FROM hotels
WHERE star_rating = 5 AND board_type IN ('AI', 'UAI')
ORDER BY price_per_night DESC, hotel_name;
```

Жолдар саны: 5

| hotel_name | board_type | price_per_night |
|---|---|---|
| Azure Bay Resort & Spa | UAI | 68000 |
| Lara Palm Garden Hotel | AI | 59000 |
| Minoan Coast Resort | AI | 57000 |
| Yalong Pearl Resort | AI | 54000 |
| Coral Sands Resort | AI | 47000 |

## Q2.2. BETWEEN: 2026 жылғы жазғы мезгілде ұшатын турлар

```sql
SELECT tour_id, package_id, departure_date, return_date, price_per_person, tour_status
FROM tours
WHERE departure_date BETWEEN '2026-06-01' AND '2026-08-31'
ORDER BY departure_date, tour_id;
```

Жолдар саны: 8

| tour_id | package_id | departure_date | return_date | price_per_person | tour_status |
|---|---|---|---|---|---|
| 66 | 23 | 2026-06-07 | 2026-06-14 | 674000 | completed |
| 58 | 19 | 2026-06-18 | 2026-06-25 | 621000 | completed |
| 9 | 2 | 2026-07-02 | 2026-07-09 | 674000 | completed |
| 23 | 6 | 2026-07-12 | 2026-07-19 | 594000 | completed |
| 1 | 1 | 2026-07-18 | 2026-07-25 | 658000 | completed |
| 67 | 23 | 2026-07-26 | 2026-08-02 | 749000 | completed |
| 44 | 13 | 2026-08-12 | 2026-08-17 | 383000 | completed |
| 57 | 19 | 2026-08-18 | 2026-08-25 | 634000 | completed |

## Q2.3. IN: виза талап ететін немесе визаны келгенде беретін елдер

```sql
SELECT country_name, entry_regime, insurance_mandatory
FROM countries
WHERE entry_regime IN ('visa_required', 'visa_on_arrival')
ORDER BY country_name;
```

Жолдар саны: 7

| country_name | entry_regime | insurance_mandatory |
|---|---|---|
| Czechia | visa_required | 1 |
| Egypt | visa_on_arrival | 0 |
| France | visa_required | 1 |
| Greece | visa_required | 1 |
| Italy | visa_required | 1 |
| Japan | visa_required | 0 |
| Spain | visa_required | 1 |

## Q2.4. LIKE: аты «Ai» әріптерінен басталатын Астана клиенттері

```sql
SELECT client_id, first_name, last_name, city
FROM clients
WHERE first_name LIKE 'Ai%' AND city = 'Astana'
ORDER BY last_name, first_name;
```

Жолдар саны: 8

| client_id | first_name | last_name | city |
|---|---|---|---|
| 260 | Ainur | Karimova | Astana |
| 118 | Aigerim | Kozlova | Astana |
| 233 | Aibek | Morozov | Astana |
| 19 | Ainur | Omarova | Astana |
| 27 | Aigerim | Petrova | Astana |
| 265 | Aibek | Sarsenov | Astana |
| 203 | Aibek | Seitkaliyev | Astana |
| 244 | Aigerim | Suleimenova | Astana |

## Q2.5. Көп шартты сүзу (AND, OR, NOT): белсенді жағалау турлары 600 мың теңгеге дейін

```sql
SELECT package_name, tour_type, duration_days, base_price
FROM tour_packages
WHERE is_active = TRUE
  AND ((tour_type = 'beach' AND base_price < 600000)
       OR (tour_type = 'city_break' AND duration_days <= 6))
  AND NOT (destination_id = 5)
ORDER BY base_price, package_name;
```

Жолдар саны: 4

| package_name | tour_type | duration_days | base_price |
|---|---|---|---|
| Baku Weekend | city_break | 4 | 345000 |
| Dubai Winter Escape | city_break | 6 | 490000 |
| Prague Christmas Markets | city_break | 5 | 590000 |
| Paris Spring Romance | city_break | 6 | 800000 |

## Q2.6. Көп шартты сүзу: 1-2 сағатқа дейін кешіккен экономклассты рейстер

```sql
SELECT flight_id, flight_number, departure_at, delay_minutes, cabin_class
FROM flights
WHERE flight_status = 'completed'
  AND cabin_class = 'economy'
  AND (delay_minutes BETWEEN 60 AND 120 OR delay_minutes > 240)
ORDER BY delay_minutes DESC, flight_id
LIMIT 15;
```

Жолдар саны: 11

| flight_id | flight_number | departure_at | delay_minutes | cabin_class |
|---|---|---|---|---|
| 25 | DV888 | 2025-10-22 21:55:00 | 106 | economy |
| 18 | KC363 | 2026-07-09 06:15:00 | 105 | economy |
| 23 | DV691 | 2026-10-16 05:45:00 | 105 | economy |
| 105 | EK654 | 2026-11-19 21:55:00 | 103 | economy |
| 143 | IQ208 | 2025-05-13 11:45:00 | 97 | economy |
| 95 | J2751 | 2025-06-08 02:55:00 | 96 | economy |
| 148 | KC119 | 2026-04-11 22:20:00 | 92 | economy |
| 77 | DV683 | 2025-02-03 09:20:00 | 86 | economy |
| 78 | DV422 | 2025-02-11 22:00:00 | 72 | economy |
| 49 | MS711 | 2025-10-20 07:40:00 | 71 | economy |
| 146 | IQ327 | 2026-09-22 04:15:00 | 68 | economy |

## Q2.7. IS NULL: 2026 жылдың қыркүйегінен кейінгі жеңілдіксіз расталған брондаулар

```sql
SELECT booking_id, client_id, tour_id, booking_date, booking_channel
FROM bookings
WHERE discount_id IS NULL
  AND booking_status = 'confirmed'
  AND booking_date >= '2026-09-01'
ORDER BY booking_date, booking_id;
```

Жолдар саны: 19

| booking_id | client_id | tour_id | booking_date | booking_channel |
|---|---|---|---|---|
| 303 | 56 | 33 | 2026-09-11 | office |
| 304 | 190 | 19 | 2026-09-12 | website |
| 306 | 151 | 69 | 2026-09-15 | website |
| 311 | 104 | 30 | 2026-09-24 | office |
| 313 | 162 | 49 | 2026-09-28 | phone |
| 314 | 210 | 24 | 2026-09-30 | office |
| 316 | 30 | 53 | 2026-10-02 | office |
| 318 | 22 | 30 | 2026-10-04 | office |
| 319 | 143 | 24 | 2026-10-05 | website |
| 322 | 236 | 19 | 2026-10-12 | website |
| 323 | 172 | 14 | 2026-10-13 | instagram |
| 324 | 261 | 69 | 2026-10-13 | phone |
| 326 | 152 | 24 | 2026-10-14 | phone |
| 329 | 64 | 24 | 2026-10-16 | website |
| 335 | 185 | 14 | 2026-10-23 | website |

## Q2.8. LIKE және NOT LIKE: атауында Resort бар, бірақ Spa жоқ қонақүйлер

```sql
SELECT hotel_name, star_rating, price_per_night
FROM hotels
WHERE hotel_name LIKE '%Resort%' AND hotel_name NOT LIKE '%Spa%'
ORDER BY hotel_name;
```

Жолдар саны: 7

| hotel_name | star_rating | price_per_night |
|---|---|---|
| Blue Cape Resort | 5 | 49000 |
| Cholpon Lakeside Resort | 3 | 21000 |
| Coral Sands Resort | 5 | 47000 |
| Kata Horizon Resort | 4 | 43000 |
| Minoan Coast Resort | 5 | 57000 |
| Ras Mohamed Dive Resort | 4 | 38000 |
| Yalong Pearl Resort | 5 | 54000 |

## Q2.9. BETWEEN: паспорты алдағы 8 айда біткен белсенді клиенттер

```sql
SELECT client_id, first_name, last_name, passport_expiry
FROM clients
WHERE passport_expiry BETWEEN '2026-11-22' AND '2027-07-31'
  AND is_active = TRUE
ORDER BY passport_expiry, client_id
LIMIT 20;
```

Жолдар саны: 20

| client_id | first_name | last_name | passport_expiry |
|---|---|---|---|
| 83 | Marat | Rakhimov | 2027-01-05 |
| 266 | Dilnaz | Yermekova | 2027-02-15 |
| 114 | Moldir | Dosmukhamedova | 2027-02-16 |
| 69 | Berik | Nurgaliyev | 2027-02-20 |
| 192 | Tatyana | Kassymova | 2027-02-28 |
| 158 | Zhanar | Kozlova | 2027-03-03 |
| 91 | Saule | Zhaksylykova | 2027-03-22 |
| 96 | Raushan | Akhmetova | 2027-03-25 |
| 89 | Gulnara | Zhaksylykova | 2027-04-05 |
| 90 | Adilet | Zhaksylykov | 2027-04-08 |
| 95 | Zhandos | Akhmetov | 2027-04-24 |
| 241 | Timur | Tulegenov | 2027-04-25 |
| 208 | Assel | Kuanysheva | 2027-05-12 |
| 44 | Igor | Kassymov | 2027-05-18 |
| 237 | Marat | Rakhimov | 2027-05-18 |
