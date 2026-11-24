# 04_joins.sql: орындау нәтижелері

JOIN сұраныстары. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q4.1. INNER JOIN (4 кесте): болашақ турлар, елі мен бағыты көрсетілген

```sql
SELECT t.tour_id, p.package_name, d.destination_name, c.country_name, t.departure_date, t.price_per_person
FROM tours t
INNER JOIN tour_packages p ON p.package_id = t.package_id
INNER JOIN destinations d  ON d.destination_id = p.destination_id
INNER JOIN countries c     ON c.country_id = d.country_id
WHERE t.departure_date > '2026-11-22' AND t.tour_status <> 'cancelled'
ORDER BY t.departure_date, t.tour_id;
```

Жолдар саны: 8

| tour_id | package_name | destination_name | country_name | departure_date | price_per_person |
|---|---|---|---|---|---|
| 30 | Phuket Island Classic | Phuket | Thailand | 2026-12-03 | 784000 |
| 24 | Hurghada Red Sea All-Inclusive | Hurghada | Egypt | 2026-12-04 | 584000 |
| 49 | Baku Weekend | Baku | Azerbaijan | 2026-12-21 | 337000 |
| 19 | Dubai and Abu Dhabi Highlights | Dubai | United Arab Emirates | 2026-12-22 | 592000 |
| 69 | Prague Christmas Markets | Prague | Czechia | 2026-12-27 | 609000 |
| 14 | Dubai Winter Escape | Dubai | United Arab Emirates | 2027-01-03 | 546000 |
| 76 | Shymbulak Ski Week | Almaty | Kazakhstan | 2027-01-14 | 323000 |
| 29 | Phuket Island Classic | Phuket | Thailand | 2027-01-27 | 869000 |

## Q4.2. INNER JOIN (4 кесте): соңғы 12 брондау: клиент, турпакет, ұшу күні

```sql
SELECT b.booking_id, b.booking_date, cl.first_name, cl.last_name, p.package_name, t.departure_date
FROM bookings b
INNER JOIN clients cl      ON cl.client_id = b.client_id
INNER JOIN tours t         ON t.tour_id = b.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
ORDER BY b.booking_date DESC, b.booking_id DESC
LIMIT 12;
```

Жолдар саны: 12

| booking_id | booking_date | first_name | last_name | package_name | departure_date |
|---|---|---|---|---|---|
| 351 | 2026-11-20 | Andrey | Kassymov | Dubai Winter Escape | 2027-01-03 |
| 350 | 2026-11-19 | Alikhan | Suleimenov | Dubai and Abu Dhabi Highlights | 2026-12-22 |
| 349 | 2026-11-19 | Zhandos | Orazov | Dubai Winter Escape | 2027-01-03 |
| 348 | 2026-11-18 | Dias | Smagulov | Shymbulak Ski Week | 2027-01-14 |
| 347 | 2026-11-16 | Aibek | Bekturov | Prague Christmas Markets | 2026-12-27 |
| 346 | 2026-11-13 | Dilnaz | Nurgaliyeva | Shymbulak Ski Week | 2027-01-14 |
| 345 | 2026-11-12 | Askar | Petrov | Shymbulak Ski Week | 2027-01-14 |
| 344 | 2026-11-12 | Aibek | Sarsenov | Phuket Island Classic | 2026-12-03 |
| 343 | 2026-11-10 | Marzhan | Kenzhebayeva | Dubai Winter Escape | 2027-01-03 |
| 342 | 2026-11-08 | Zhandos | Kenzhebayev | Baku Weekend | 2026-12-21 |
| 341 | 2026-11-08 | Talgat | Kenzhebayev | Dubai Winter Escape | 2027-01-03 |
| 340 | 2026-11-08 | Zhibek | Tulegenova | Dubai Winter Escape | 2027-01-03 |

## Q4.3. LEFT JOIN: бірде-бір рет брондау жасамаған клиенттер

```sql
SELECT cl.client_id, cl.first_name, cl.last_name, cl.city, cl.registration_date
FROM clients cl
LEFT JOIN booking_participants bp ON bp.client_id = cl.client_id
WHERE bp.participant_id IS NULL
ORDER BY cl.registration_date, cl.client_id;
```

Жолдар саны: 17

| client_id | first_name | last_name | city | registration_date |
|---|---|---|---|---|
| 280 | Assel | Zhumabekova | Astana | 2025-01-09 |
| 277 | Viktor | Seitkaliyev | Astana | 2025-02-19 |
| 274 | Balzhan | Petrova | Pavlodar | 2025-02-21 |
| 282 | Daulet | Sidorov | Almaty | 2025-06-07 |
| 279 | Irina | Morozova | Astana | 2025-07-10 |
| 165 | Talgat | Shaikenov | Oral | 2025-07-15 |
| 275 | Karina | Orazova | Almaty | 2025-07-26 |
| 284 | Alexey | Zhumabekov | Shymkent | 2025-09-23 |
| 157 | Dias | Kozlov | Karaganda | 2025-11-15 |
| 158 | Zhanar | Kozlova | Karaganda | 2026-01-24 |
| 271 | Serik | Alimov | Almaty | 2026-02-11 |
| 276 | Ruslan | Omarov | Pavlodar | 2026-02-13 |
| 283 | Timur | Beisenov | Almaty | 2026-02-18 |
| 166 | Svetlana | Shaikenova | Oral | 2026-05-02 |
| 273 | Gaukhar | Tulegenova | Almaty | 2026-06-16 |

## Q4.4. LEFT JOIN: брондауы жоқ немесе барлық брондауы бас тартылған турлар

```sql
SELECT t.tour_id, p.package_name, t.departure_date, t.tour_status,
       COUNT(b.booking_id) AS active_bookings
FROM tours t
INNER JOIN tour_packages p ON p.package_id = t.package_id
LEFT JOIN bookings b ON b.tour_id = t.tour_id AND b.booking_status <> 'cancelled'
GROUP BY t.tour_id, p.package_name, t.departure_date, t.tour_status
HAVING COUNT(b.booking_id) = 0
ORDER BY t.departure_date;
```

Жолдар саны: 4

| tour_id | package_name | departure_date | tour_status | active_bookings |
|---|---|---|---|---|
| 77 | Shymbulak Ski Week | 2025-02-06 | completed | 0 |
| 47 | Samarkand Silk Road | 2026-04-10 | cancelled | 0 |
| 40 | Phu Quoc Island Retreat | 2026-12-13 | cancelled | 0 |
| 56 | Sri Lanka Colombo and Coast | 2027-01-19 | cancelled | 0 |

## Q4.5. RIGHT JOIN: ешқандай турпакетке кірмеген қонақүйлер

```sql
SELECT h.hotel_id, h.hotel_name, h.star_rating
FROM package_hotels ph
RIGHT JOIN hotels h ON h.hotel_id = ph.hotel_id
WHERE ph.package_id IS NULL
ORDER BY h.hotel_name;
```

Жолдар саны: 3

| hotel_id | hotel_name | star_rating |
|---|---|---|
| 6 | Creek View Grand | 5 |
| 3 | Kemer Pine Residence | 4 |
| 9 | Sunset Reef Hotel | 4 |

## Q4.6. FULL OUTER JOIN (LEFT JOIN UNION RIGHT JOIN): бағыттар мен турпакеттердің сәйкестігі

```sql
SELECT d.destination_name, p.package_name,
       CASE WHEN p.package_id IS NULL THEN 'бағытқа турпакет жоқ'
            WHEN d.destination_id IS NULL THEN 'турпакеттің бағыты жоқ'
            ELSE 'сәйкес' END AS match_status
FROM destinations d
LEFT JOIN tour_packages p ON p.destination_id = d.destination_id
UNION
SELECT d.destination_name, p.package_name,
       CASE WHEN p.package_id IS NULL THEN 'бағытқа турпакет жоқ'
            WHEN d.destination_id IS NULL THEN 'турпакеттің бағыты жоқ'
            ELSE 'сәйкес' END AS match_status
FROM destinations d
RIGHT JOIN tour_packages p ON p.destination_id = d.destination_id
ORDER BY match_status, destination_name, package_name;
```

Жолдар саны: 33

| destination_name | package_name | match_status |
|---|---|---|
| Abu Dhabi | NULL | бағытқа турпакет жоқ |
| Astana | NULL | бағытқа турпакет жоқ |
| Batumi | NULL | бағытқа турпакет жоқ |
| Koh Samui | NULL | бағытқа турпакет жоқ |
| Tashkent | NULL | бағытқа турпакет жоқ |
| Aktau | Mangystau Expedition | сәйкес |
| Almaty | Almaty Mountains and Charyn | сәйкес |
| Almaty | Shymbulak Ski Week | сәйкес |
| Antalya | Antalya Family All-Inclusive | сәйкес |
| Antalya | Antalya Premium Resort Week | сәйкес |
| Baku | Baku Weekend | сәйкес |
| Bangkok | Bangkok and Koh Samui | сәйкес |
| Barcelona | Barcelona Mediterranean City | сәйкес |
| Colombo | Sri Lanka Colombo and Coast | сәйкес |
| Dubai | Dubai Winter Escape | сәйкес |

## Q4.7. INNER JOIN (6 кесте): ел бойынша түскен түсім (қайтарымдар шегеріліп)

```sql
SELECT c.country_name,
       SUM(CASE WHEN py.payment_type = 'refund' THEN -py.amount ELSE py.amount END) AS net_revenue,
       COUNT(DISTINCT b.booking_id) AS bookings_cnt
FROM payments py
INNER JOIN bookings b      ON b.booking_id = py.booking_id
INNER JOIN tours t         ON t.tour_id = b.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
INNER JOIN destinations d  ON d.destination_id = p.destination_id
INNER JOIN countries c     ON c.country_id = d.country_id
WHERE py.payment_status = 'completed'
GROUP BY c.country_name
ORDER BY net_revenue DESC, c.country_name
LIMIT 10;
```

Жолдар саны: 10

| country_name | net_revenue | bookings_cnt |
|---|---|---|
| Turkey | 104071999 | 79 |
| Thailand | 53682560 | 31 |
| Egypt | 49914540 | 40 |
| United Arab Emirates | 39428970 | 48 |
| Vietnam | 28094866 | 21 |
| Greece | 21636740 | 15 |
| Maldives | 15321600 | 5 |
| Georgia | 14123255 | 16 |
| France | 11524880 | 6 |
| Spain | 10425800 | 9 |

## Q4.8. INNER JOIN (4 кесте): гидтердің жүктемесі (тур саны мен жұмыс күндері)

```sql
SELECT g.full_name, tg.assignment_role, COUNT(*) AS tours_cnt, SUM(p.duration_days) AS work_days
FROM guides g
INNER JOIN tour_guides tg  ON tg.guide_id = g.guide_id
INNER JOIN tours t         ON t.tour_id = tg.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
WHERE t.tour_status = 'completed'
GROUP BY g.full_name, tg.assignment_role
ORDER BY work_days DESC, g.full_name
LIMIT 10;
```

Жолдар саны: 10

| full_name | assignment_role | tours_cnt | work_days |
|---|---|---|---|
| Marat Zhaksybekov | lead | 18 | 132 |
| Dinara Kuandykova | lead | 11 | 86 |
| Emre Kaya | local_expert | 11 | 79 |
| Aidos Bekmuratov | lead | 9 | 67 |
| Sergey Lim | lead | 9 | 66 |
| Aliya Nurmagambetova | lead | 9 | 62 |
| Somchai Prasert | local_expert | 4 | 42 |
| Mahmoud Hassan | local_expert | 5 | 40 |
| Rashid Khalil | local_expert | 6 | 38 |
| Anton Belov | assistant | 4 | 30 |

## Q4.9. Өзіне-өзі қосу (бір кесте екі рет): ең жиі ұшатын маршруттар

```sql
SELECT o.destination_name AS origin_city, a.destination_name AS arrival_city, COUNT(*) AS flights_cnt
FROM flights f
INNER JOIN destinations o ON o.destination_id = f.origin_destination_id
INNER JOIN destinations a ON a.destination_id = f.arrival_destination_id
WHERE f.flight_status <> 'cancelled'
GROUP BY o.destination_name, a.destination_name
ORDER BY flights_cnt DESC, origin_city, arrival_city
LIMIT 10;
```

Жолдар саны: 10

| origin_city | arrival_city | flights_cnt |
|---|---|---|
| Antalya | Astana | 9 |
| Astana | Antalya | 9 |
| Almaty | Hurghada | 5 |
| Astana | Dubai | 5 |
| Dubai | Astana | 5 |
| Hurghada | Almaty | 5 |
| Almaty | Astana | 4 |
| Astana | Almaty | 4 |
| Almaty | Dubai | 3 |
| Almaty | Phuket | 3 |

## Q4.10. INNER JOIN (5 кесте): визасы қабылданбаған жолаушылар елдер бойынша

```sql
SELECT c.country_name, COUNT(*) AS rejected_visas
FROM booking_participants bp
INNER JOIN bookings b      ON b.booking_id = bp.booking_id
INNER JOIN tours t         ON t.tour_id = b.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
INNER JOIN destinations d  ON d.destination_id = p.destination_id
INNER JOIN countries c     ON c.country_id = d.country_id
WHERE bp.visa_status = 'rejected'
GROUP BY c.country_name
ORDER BY rejected_visas DESC, c.country_name;
```

Жолдар саны: 2

| country_name | rejected_visas |
|---|---|
| Greece | 6 |
| Italy | 2 |

## Q4.11. INNER JOIN (4 кесте): турпакеттер бойынша пікірлердің орташа бағасы

```sql
SELECT p.package_name, COUNT(r.review_id) AS reviews_cnt,
       ROUND(AVG(r.overall_rating), 2) AS avg_overall, ROUND(AVG(r.hotel_rating), 2) AS avg_hotel
FROM reviews r
INNER JOIN bookings b      ON b.booking_id = r.booking_id
INNER JOIN tours t         ON t.tour_id = b.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
GROUP BY p.package_name
HAVING COUNT(r.review_id) >= 3
ORDER BY avg_overall DESC, p.package_name
LIMIT 10;
```

Жолдар саны: 10

| package_name | reviews_cnt | avg_overall | avg_hotel |
|---|---|---|---|
| Bangkok and Koh Samui | 4 | 5 | 5 |
| Hurghada Red Sea All-Inclusive | 9 | 4.56 | 4.33 |
| Barcelona Mediterranean City | 4 | 4.5 | 4 |
| Antalya Premium Resort Week | 10 | 4.4 | 4.3 |
| Issyk-Kul Lakeside Summer | 5 | 4.4 | 4.4 |
| Montenegro Adriatic Summer | 3 | 4.33 | 4 |
| Phu Quoc Island Retreat | 3 | 4.33 | 4.33 |
| Dubai Winter Escape | 14 | 4.29 | 4.29 |
| Crete Aegean Holiday | 6 | 4.17 | 4.17 |
| Tbilisi and Batumi Combo | 6 | 4.17 | 4 |

## Q4.12. PostgreSQL-дегі тікелей FULL OUTER JOIN (Q4.6 нәтижесімен салыстыру үшін)

```sql
SELECT d.destination_name, p.package_name
FROM destinations d
FULL OUTER JOIN tour_packages p ON p.destination_id = d.destination_id
WHERE p.package_id IS NULL OR d.destination_id IS NULL
ORDER BY d.destination_name;
```

Жолдар саны: 5

| destination_name | package_name |
|---|---|
| Abu Dhabi | NULL |
| Astana | NULL |
| Batumi | NULL |
| Koh Samui | NULL |
| Tashkent | NULL |
