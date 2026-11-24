# 03_aggregation.sql: орындау нәтижелері

Агрегаттау, GROUP BY, HAVING. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q3.1. COUNT: брондаулар мен брондау жасаған бірегей клиенттер саны

```sql
SELECT COUNT(*) AS total_bookings,
       COUNT(DISTINCT client_id) AS booking_clients,
       COUNT(cancellation_date) AS cancelled_bookings
FROM bookings;
```

Жолдар саны: 1

| total_bookings | booking_clients | cancelled_bookings |
|---|---|---|
| 351 | 184 | 35 |

## Q3.2. SUM: сәтті өткен түсімдердің жалпы сомасы (қайтарымдарсыз)

```sql
SELECT SUM(amount) AS received_total
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund';
```

Жолдар саны: 1

| received_total |
|---|
| 418631230 |

## Q3.3. AVG: аяқталған турлардың бір адамға орташа бағасы және орташа өзіндік құны

```sql
SELECT ROUND(AVG(price_per_person), 0) AS avg_price,
       ROUND(AVG(net_cost_per_person), 0) AS avg_cost
FROM tours
WHERE tour_status = 'completed';
```

Жолдар саны: 1

| avg_price | avg_cost |
|---|---|
| 614810 | 519524 |

## Q3.4. MIN және MAX: тур бағасының диапазоны мен сыйымдылығы

```sql
SELECT MIN(price_per_person) AS min_price, MAX(price_per_person) AS max_price,
       MIN(max_participants) AS min_capacity, MAX(max_participants) AS max_capacity
FROM tours;
```

Жолдар саны: 1

| min_price | max_price | min_capacity | max_capacity |
|---|---|---|---|
| 232000 | 1263000 | 10 | 30 |

## Q3.5. AVG: пікірлердің орташа бағалары

```sql
SELECT ROUND(AVG(overall_rating), 2) AS overall,
       ROUND(AVG(hotel_rating), 2) AS hotel,
       ROUND(AVG(guide_rating), 2) AS guide,
       ROUND(AVG(service_rating), 2) AS service,
       COUNT(*) AS reviews_cnt
FROM reviews;
```

Жолдар саны: 1

| overall | hotel | guide | service | reviews_cnt |
|---|---|---|---|---|
| 4.21 | 4.12 | 4.08 | 3.99 | 114 |

## Q3.6. SUM және MAX: бұғатталған авиаорындар және ең ұзақ кешігу

```sql
SELECT SUM(seats_blocked) AS blocked_seats, MAX(delay_minutes) AS max_delay
FROM flights
WHERE flight_status <> 'cancelled';
```

Жолдар саны: 1

| blocked_seats | max_delay |
|---|---|
| 2788 | 227 |

## Q3.7. Брондаулар саны статус бойынша

```sql
SELECT booking_status, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY booking_status
ORDER BY bookings_cnt DESC;
```

Жолдар саны: 4

| booking_status | bookings_cnt |
|---|---|
| completed | 269 |
| confirmed | 40 |
| cancelled | 35 |
| pending | 7 |

## Q3.8. Сату арналары бойынша брондаулар саны

```sql
SELECT booking_channel, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY booking_channel
ORDER BY bookings_cnt DESC, booking_channel;
```

Жолдар саны: 5

| booking_channel | bookings_cnt |
|---|---|
| office | 119 |
| website | 103 |
| instagram | 71 |
| phone | 35 |
| partner | 23 |

## Q3.9. Жолаушы түрі бойынша саны және жиынтық баға

```sql
SELECT traveler_type, COUNT(*) AS travelers, SUM(unit_price) AS gross_sum, ROUND(AVG(unit_price), 0) AS avg_price
FROM booking_participants
GROUP BY traveler_type
ORDER BY travelers DESC;
```

Жолдар саны: 3

| traveler_type | travelers | gross_sum | avg_price |
|---|---|---|---|
| adult | 687 | 425819000 | 619824 |
| child | 73 | 34069100 | 466700 |
| infant | 20 | 1174500 | 58725 |

## Q3.10. Төлем әдісі бойынша сәтті түсімдер

```sql
SELECT payment_method, COUNT(*) AS payments_cnt, SUM(amount) AS total_amount
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund'
GROUP BY payment_method
ORDER BY total_amount DESC;
```

Жолдар саны: 5

| payment_method | payments_cnt | total_amount |
|---|---|---|
| card | 234 | 170103815 |
| mobile_banking | 177 | 122932020 |
| bank_transfer | 92 | 67863880 |
| cash | 64 | 48906315 |
| installment | 16 | 8825200 |

## Q3.11. Авиакомпания бойынша аяқталған рейстердің орташа кешігуі

```sql
SELECT airline_id, COUNT(*) AS flights_cnt, ROUND(AVG(delay_minutes), 1) AS avg_delay
FROM flights
WHERE flight_status = 'completed'
GROUP BY airline_id
ORDER BY avg_delay DESC, airline_id;
```

Жолдар саны: 15

| airline_id | flights_cnt | avg_delay |
|---|---|---|
| 17 | 4 | 64.5 |
| 4 | 11 | 57.9 |
| 14 | 2 | 48 |
| 3 | 4 | 41.3 |
| 2 | 28 | 24.3 |
| 13 | 2 | 19.5 |
| 15 | 2 | 19.5 |
| 1 | 42 | 18.4 |
| 16 | 2 | 15 |
| 7 | 4 | 13 |
| 10 | 3 | 11.7 |
| 6 | 11 | 10.9 |
| 9 | 8 | 8.9 |
| 5 | 4 | 0 |
| 12 | 2 | 0 |

## Q3.12. Баға (жұлдыз) бойынша қонақүйлер саны мен орташа тариф

```sql
SELECT star_rating, COUNT(*) AS hotels_cnt, ROUND(AVG(price_per_night), 0) AS avg_rate
FROM hotels
GROUP BY star_rating
ORDER BY star_rating DESC;
```

Жолдар саны: 3

| star_rating | hotels_cnt | avg_rate |
|---|---|---|
| 5 | 11 | 75727 |
| 4 | 23 | 46478 |
| 3 | 1 | 21000 |

## Q3.13. Бас тартылмаған 3 және одан көп брондауы бар клиенттер

```sql
SELECT client_id, COUNT(*) AS bookings_cnt
FROM bookings
WHERE booking_status <> 'cancelled'
GROUP BY client_id
HAVING COUNT(*) >= 3
ORDER BY bookings_cnt DESC, client_id;
```

Жолдар саны: 34

| client_id | bookings_cnt |
|---|---|
| 231 | 5 |
| 261 | 5 |
| 265 | 5 |
| 25 | 4 |
| 162 | 4 |
| 203 | 4 |
| 256 | 4 |
| 258 | 4 |
| 17 | 3 |
| 29 | 3 |
| 46 | 3 |
| 50 | 3 |
| 53 | 3 |
| 64 | 3 |
| 67 | 3 |

## Q3.14. Орташа кешігуі 20 минуттан асатын авиакомпаниялар (аяқталған рейстер ғана)

```sql
SELECT airline_id, COUNT(*) AS flights_cnt, ROUND(AVG(delay_minutes), 1) AS avg_delay
FROM flights
WHERE flight_status = 'completed'
GROUP BY airline_id
HAVING AVG(delay_minutes) > 20
ORDER BY avg_delay DESC;
```

Жолдар саны: 5

| airline_id | flights_cnt | avg_delay |
|---|---|---|
| 17 | 4 | 64.5 |
| 4 | 11 | 57.9 |
| 14 | 2 | 48 |
| 3 | 4 | 41.3 |
| 2 | 28 | 24.3 |

## Q3.15. Бір брондау бойынша түскен сома 2 млн теңгеден асатын брондаулар

```sql
SELECT booking_id, COUNT(*) AS payments_cnt, SUM(amount) AS paid_total
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund'
GROUP BY booking_id
HAVING SUM(amount) > 2000000
ORDER BY paid_total DESC, booking_id
LIMIT 15;
```

Жолдар саны: 15

| booking_id | payments_cnt | paid_total |
|---|---|---|
| 316 | 2 | 5265600 |
| 207 | 1 | 3648000 |
| 321 | 1 | 3238700 |
| 1 | 2 | 3078700 |
| 122 | 1 | 3073400 |
| 29 | 2 | 2988700 |
| 303 | 1 | 2947000 |
| 311 | 2 | 2940000 |
| 268 | 2 | 2892700 |
| 257 | 3 | 2875460 |
| 261 | 3 | 2864500 |
| 169 | 2 | 2765400 |
| 243 | 2 | 2749920 |
| 259 | 2 | 2696000 |
| 177 | 2 | 2545410 |

## Q3.16. 4-5 жұлдызды қонақүйлері бар, орташа тарифі 50 мың теңгеден жоғары бағыттар

```sql
SELECT destination_id, COUNT(*) AS hotels_cnt, ROUND(AVG(price_per_night), 0) AS avg_rate
FROM hotels
WHERE star_rating >= 4
GROUP BY destination_id
HAVING AVG(price_per_night) > 50000
ORDER BY avg_rate DESC;
```

Жолдар саны: 14

| destination_id | hotels_cnt | avg_rate |
|---|---|---|
| 22 | 1 | 210000 |
| 26 | 1 | 84000 |
| 7 | 1 | 79000 |
| 30 | 1 | 78000 |
| 6 | 2 | 75000 |
| 25 | 1 | 72000 |
| 27 | 1 | 69000 |
| 14 | 1 | 64000 |
| 28 | 1 | 57000 |
| 4 | 3 | 56000 |
| 15 | 1 | 54000 |
| 12 | 1 | 52000 |
| 29 | 1 | 52000 |
| 10 | 2 | 50500 |

## Q3.17. Кемінде 8 рет қолданылған жеңілдіктер

```sql
SELECT discount_id, COUNT(*) AS used_cnt
FROM bookings
WHERE discount_id IS NOT NULL
GROUP BY discount_id
HAVING COUNT(*) >= 8
ORDER BY used_cnt DESC, discount_id;
```

Жолдар саны: 4

| discount_id | used_cnt |
|---|---|
| 3 | 55 |
| 11 | 50 |
| 1 | 20 |
| 14 | 17 |

## Q3.18. Кемінде 3 пікірі бар және орташа бағасы 4.3-тен төмен турлар (2025 жылдан бастап)

```sql
SELECT b.tour_id, COUNT(*) AS reviews_cnt, ROUND(AVG(r.overall_rating), 2) AS avg_rating
FROM reviews r
JOIN bookings b ON b.booking_id = r.booking_id
WHERE r.review_date >= '2025-01-01'
GROUP BY b.tour_id
HAVING COUNT(*) >= 3 AND AVG(r.overall_rating) < 4.3
ORDER BY avg_rating, b.tour_id;
```

Жолдар саны: 10

| tour_id | reviews_cnt | avg_rating |
|---|---|---|
| 45 | 3 | 3.33 |
| 61 | 3 | 3.33 |
| 13 | 4 | 3.5 |
| 15 | 4 | 3.5 |
| 38 | 4 | 3.75 |
| 4 | 3 | 4 |
| 9 | 3 | 4 |
| 31 | 4 | 4 |
| 51 | 3 | 4 |
| 5 | 4 | 4.25 |

## Q3.19. WHERE мен HAVING айырмасы: бір шарт екі жерде

```sql
SELECT client_id, COUNT(*) AS completed_cnt
FROM bookings
WHERE booking_status = 'completed'
GROUP BY client_id
HAVING COUNT(*) >= 2
ORDER BY completed_cnt DESC, client_id
LIMIT 10;
```

Жолдар саны: 10

| client_id | completed_cnt |
|---|---|
| 231 | 5 |
| 25 | 4 |
| 256 | 4 |
| 258 | 4 |
| 261 | 4 |
| 17 | 3 |
| 29 | 3 |
| 50 | 3 |
| 67 | 3 |
| 123 | 3 |

## Q3.20. (ә) HAVING топтарды есептегеннен кейін сүзеді: барлық брондау саны 4+ болған клиенттер

```sql
SELECT client_id, COUNT(*) AS all_bookings,
       SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt
FROM bookings
GROUP BY client_id
HAVING COUNT(*) >= 4
ORDER BY all_bookings DESC, client_id
LIMIT 10;
```

Жолдар саны: 10

| client_id | all_bookings | completed_cnt |
|---|---|---|
| 231 | 5 | 5 |
| 261 | 5 | 4 |
| 265 | 5 | 3 |
| 25 | 4 | 4 |
| 123 | 4 | 3 |
| 162 | 4 | 2 |
| 203 | 4 | 3 |
| 239 | 4 | 3 |
| 256 | 4 | 4 |
| 258 | 4 | 4 |

## Q3.21. WHERE мен HAVING айырмасы: Q3.13-тің WHERE шартынсыз нұсқасы (бас тартылған брондаулар да саналады)

```sql
SELECT client_id, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY client_id
HAVING COUNT(*) >= 3
ORDER BY bookings_cnt DESC, client_id;
```

Жолдар саны: 42

| client_id | bookings_cnt |
|---|---|
| 231 | 5 |
| 261 | 5 |
| 265 | 5 |
| 25 | 4 |
| 123 | 4 |
| 162 | 4 |
| 203 | 4 |
| 239 | 4 |
| 256 | 4 |
| 258 | 4 |
| 1 | 3 |
| 17 | 3 |
| 29 | 3 |
| 46 | 3 |
| 50 | 3 |
