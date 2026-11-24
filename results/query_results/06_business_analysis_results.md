# 06_business_analysis.sql: орындау нәтижелері

Бизнес-талдау. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q6.1. Ең сұранысқа ие елдер: брондау, жолаушы, түсім, үлес және орын

```sql
SELECT c.country_name,
       COUNT(*) AS bookings_cnt,
       SUM(v.participants_cnt) AS travelers,
       SUM(v.net_amount) AS revenue,
       ROUND(100.0 * SUM(v.net_amount) / SUM(SUM(v.net_amount)) OVER (), 1) AS revenue_share_pct,
       RANK() OVER (ORDER BY SUM(v.participants_cnt) DESC) AS demand_rank
FROM v_booking_financials v
JOIN tours t         ON t.tour_id = v.tour_id
JOIN tour_packages p ON p.package_id = t.package_id
JOIN destinations d  ON d.destination_id = p.destination_id
JOIN countries c     ON c.country_id = d.country_id
WHERE v.booking_status IN ('completed', 'confirmed')
GROUP BY c.country_name
ORDER BY travelers DESC, c.country_name
LIMIT 10;
```

Жолдар саны: 10

| country_name | bookings_cnt | travelers | revenue | revenue_share_pct | demand_rank |
|---|---|---|---|---|---|
| Turkey | 72 | 180 | 101493499 | 25.4 | 1 |
| Egypt | 39 | 87 | 50546340 | 12.7 | 2 |
| United Arab Emirates | 45 | 86 | 43088630 | 10.8 | 3 |
| Thailand | 30 | 70 | 52874220 | 13.2 | 4 |
| Georgia | 15 | 37 | 13355255 | 3.3 | 5 |
| Vietnam | 17 | 34 | 26372566 | 6.6 | 6 |
| Greece | 12 | 29 | 19319940 | 4.8 | 7 |
| Kyrgyzstan | 11 | 28 | 6876580 | 1.7 | 8 |
| Kazakhstan | 16 | 27 | 7585280 | 1.9 | 9 |
| France | 6 | 15 | 11524880 | 2.9 | 10 |

## Q6.2. Ең сұранысқа ие бағыттар: жолаушы саны және бір жолаушыға орташа түсім

```sql
SELECT d.destination_name, c.country_name,
       COUNT(*) AS bookings_cnt,
       SUM(v.participants_cnt) AS travelers,
       ROUND(1.0 * SUM(v.participants_cnt) / COUNT(*), 2) AS avg_party_size,
       ROUND(SUM(v.net_amount) / SUM(v.participants_cnt), 0) AS revenue_per_traveler
FROM v_booking_financials v
JOIN tours t         ON t.tour_id = v.tour_id
JOIN tour_packages p ON p.package_id = t.package_id
JOIN destinations d  ON d.destination_id = p.destination_id
JOIN countries c     ON c.country_id = d.country_id
WHERE v.booking_status IN ('completed', 'confirmed')
GROUP BY d.destination_name, c.country_name
ORDER BY travelers DESC, d.destination_name
LIMIT 10;
```

Жолдар саны: 10

| destination_name | country_name | bookings_cnt | travelers | avg_party_size | revenue_per_traveler |
|---|---|---|---|---|---|
| Antalya | Turkey | 59 | 153 | 2.59 | 583247 |
| Dubai | United Arab Emirates | 45 | 86 | 1.91 | 501031 |
| Hurghada | Egypt | 29 | 71 | 2.45 | 563525 |
| Phuket | Thailand | 19 | 48 | 2.53 | 757964 |
| Tbilisi | Georgia | 15 | 37 | 2.47 | 360953 |
| Heraklion | Greece | 12 | 29 | 2.42 | 666205 |
| Issyk-Kul | Kyrgyzstan | 11 | 28 | 2.55 | 245592 |
| Istanbul | Turkey | 13 | 27 | 2.08 | 453955 |
| Nha Trang | Vietnam | 11 | 24 | 2.18 | 750107 |
| Bangkok | Thailand | 11 | 22 | 2 | 749635 |

## Q6.3. Рентабельді турпакеттер: аяқталған турлар бойынша түсім, шығын, пайда және маржа

```sql
WITH tour_fin AS (
    SELECT t.tour_id, t.package_id, t.net_cost_per_person,
           SUM(v.net_amount) AS revenue,
           SUM(v.participants_cnt) AS travelers
    FROM tours t
    JOIN v_booking_financials v ON v.tour_id = t.tour_id AND v.booking_status = 'completed'
    WHERE t.tour_status = 'completed'
    GROUP BY t.tour_id, t.package_id, t.net_cost_per_person
)
SELECT p.package_name,
       COUNT(*) AS tours_cnt,
       SUM(f.travelers) AS travelers,
       SUM(f.revenue) AS revenue,
       SUM(f.travelers * f.net_cost_per_person) AS direct_cost,
       SUM(f.revenue) - SUM(f.travelers * f.net_cost_per_person) AS profit,
       ROUND(100.0 * (SUM(f.revenue) - SUM(f.travelers * f.net_cost_per_person)) / SUM(f.revenue), 1) AS margin_pct,
       RANK() OVER (ORDER BY SUM(f.revenue) - SUM(f.travelers * f.net_cost_per_person) DESC) AS profit_rank
FROM tour_fin f
JOIN tour_packages p ON p.package_id = f.package_id
GROUP BY p.package_name
HAVING SUM(f.revenue) > 0
ORDER BY profit DESC, p.package_name
LIMIT 12;
```

Жолдар саны: 12

| package_name | tours_cnt | travelers | revenue | direct_cost | profit | margin_pct | profit_rank |
|---|---|---|---|---|---|---|---|
| Antalya Family All-Inclusive | 6 | 102 | 58407269 | 54199000 | 4208269 | 7.2 | 1 |
| Dubai Winter Escape | 4 | 52 | 23923170 | 21433000 | 2490170 | 10.4 | 2 |
| Sharm El Sheikh Diving Week | 2 | 16 | 10536040 | 8532000 | 2004040 | 19 | 3 |
| Phuket Island Classic | 2 | 29 | 21910340 | 19980000 | 1930340 | 8.8 | 4 |
| Hurghada Red Sea All-Inclusive | 4 | 55 | 31067800 | 29311000 | 1756800 | 5.7 | 5 |
| Antalya Premium Resort Week | 4 | 51 | 30829450 | 29263000 | 1566450 | 5.1 | 6 |
| Tbilisi and Batumi Combo | 3 | 37 | 13355255 | 11831000 | 1524255 | 11.4 | 7 |
| Paris Spring Romance | 2 | 15 | 11524880 | 10085000 | 1439880 | 12.5 | 8 |
| Sanya Hainan Winter Sun | 2 | 13 | 9650000 | 8258000 | 1392000 | 14.4 | 9 |
| Crete Aegean Holiday | 3 | 29 | 19319940 | 17940000 | 1379940 | 7.1 | 10 |
| Dubai and Abu Dhabi Highlights | 2 | 18 | 10320880 | 8970000 | 1350880 | 13.1 | 11 |
| Nha Trang Sea Break | 3 | 24 | 18002566 | 16688000 | 1314566 | 7.3 | 12 |

## Q6.4. Маусымдық белсенділік: ұшу айы бойынша жолаушылар мен түсім үлесі

```sql
SELECT EXTRACT(MONTH FROM t.departure_date) AS dep_month,
       COUNT(DISTINCT t.tour_id) AS tours_cnt,
       SUM(v.participants_cnt) AS travelers,
       SUM(v.net_amount) AS revenue,
       ROUND(100.0 * SUM(v.participants_cnt) / SUM(SUM(v.participants_cnt)) OVER (), 1) AS travelers_share_pct
FROM tours t
JOIN v_booking_financials v ON v.tour_id = t.tour_id
WHERE v.booking_status IN ('completed', 'confirmed')
GROUP BY EXTRACT(MONTH FROM t.departure_date)
ORDER BY dep_month;
```

Жолдар саны: 12

| dep_month | tours_cnt | travelers | revenue | travelers_share_pct |
|---|---|---|---|---|
| 1 | 6 | 52 | 30781670 | 7.6 |
| 2 | 7 | 50 | 37849460 | 7.3 |
| 3 | 6 | 63 | 36467640 | 9.2 |
| 4 | 3 | 11 | 8072240 | 1.6 |
| 5 | 10 | 88 | 52761620 | 12.8 |
| 6 | 5 | 46 | 20003180 | 6.7 |
| 7 | 8 | 102 | 58862255 | 14.8 |
| 8 | 6 | 64 | 29623795 | 9.3 |
| 9 | 3 | 26 | 11255240 | 3.8 |
| 10 | 8 | 87 | 51233780 | 12.7 |
| 11 | 3 | 19 | 17658460 | 2.8 |
| 12 | 8 | 79 | 44988470 | 11.5 |

## Q6.5. Турлардың толу коэффициенті (load factor), аяқталған турлар

```sql
WITH tour_load AS (
    SELECT t.tour_id, t.package_id, t.max_participants,
           COALESCE(SUM(v.participants_cnt), 0) AS travelers
    FROM tours t
    LEFT JOIN v_booking_financials v ON v.tour_id = t.tour_id AND v.booking_status = 'completed'
    WHERE t.tour_status = 'completed'
    GROUP BY t.tour_id, t.package_id, t.max_participants
)
SELECT p.package_name,
       COUNT(*) AS tours_cnt,
       ROUND(100.0 * SUM(l.travelers) / SUM(l.max_participants), 1) AS load_factor_pct,
       SUM(CASE WHEN 1.0 * l.travelers / l.max_participants >= 0.9 THEN 1 ELSE 0 END) AS sold_out_tours,
       SUM(CASE WHEN 1.0 * l.travelers / l.max_participants < 0.4 THEN 1 ELSE 0 END) AS weak_tours
FROM tour_load l
JOIN tour_packages p ON p.package_id = l.package_id
GROUP BY p.package_name
ORDER BY load_factor_pct DESC, p.package_name
LIMIT 12;
```

Жолдар саны: 12

| package_name | tours_cnt | load_factor_pct | sold_out_tours | weak_tours |
|---|---|---|---|---|
| Tbilisi and Batumi Combo | 3 | 75.5 | 2 | 0 |
| Antalya Family All-Inclusive | 6 | 61.8 | 0 | 1 |
| Sharm El Sheikh Diving Week | 2 | 59.3 | 0 | 1 |
| Istanbul Heritage City Break | 3 | 58.7 | 0 | 1 |
| Issyk-Kul Lakeside Summer | 3 | 57.1 | 0 | 0 |
| Phuket Island Classic | 2 | 56.9 | 0 | 0 |
| Antalya Premium Resort Week | 4 | 56 | 0 | 0 |
| Paris Spring Romance | 2 | 55.6 | 0 | 0 |
| Phu Quoc Island Retreat | 1 | 55.6 | 0 | 0 |
| Dubai Winter Escape | 4 | 55.3 | 0 | 1 |
| Dubai and Abu Dhabi Highlights | 2 | 52.9 | 0 | 1 |
| Hurghada Red Sea All-Inclusive | 4 | 50 | 0 | 0 |

## Q6.6. Бас тартулардың себептері, үлесі және жоғалған түсім

```sql
SELECT b.cancellation_reason,
       COUNT(*) AS cancelled_cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct,
       SUM(v.net_amount) AS booked_amount
FROM bookings b
JOIN v_booking_financials v ON v.booking_id = b.booking_id
WHERE b.booking_status = 'cancelled'
GROUP BY b.cancellation_reason
ORDER BY cancelled_cnt DESC, b.cancellation_reason;
```

Жолдар саны: 6

| cancellation_reason | cancelled_cnt | share_pct | booked_amount |
|---|---|---|---|
| client_request | 16 | 45.7 | 17861360 |
| illness | 4 | 11.4 | 6117860 |
| payment_overdue | 4 | 11.4 | 3480400 |
| tour_cancelled | 4 | 11.4 | 6452200 |
| visa_refused | 4 | 11.4 | 6041040 |
| schedule_conflict | 3 | 8.6 | 4934000 |

## Q6.7. Бас тарту деңгейі турпакет түрі бойынша

```sql
SELECT p.tour_type,
       COUNT(*) AS bookings_cnt,
       SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt,
       ROUND(100.0 * SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM bookings b
JOIN tours t         ON t.tour_id = b.tour_id
JOIN tour_packages p ON p.package_id = t.package_id
GROUP BY p.tour_type
ORDER BY cancel_rate_pct DESC, p.tour_type;
```

Жолдар саны: 6

| tour_type | bookings_cnt | cancelled_cnt | cancel_rate_pct |
|---|---|---|---|
| ski | 5 | 1 | 20 |
| wellness | 21 | 4 | 19 |
| cultural | 59 | 8 | 13.6 |
| beach | 161 | 14 | 8.7 |
| city_break | 81 | 7 | 8.6 |
| adventure | 24 | 1 | 4.2 |

## Q6.8. Жеңілдіктердің тиімділігі: қолданылу саны, берілген жеңілдік және орташа чек

```sql
SELECT COALESCE(d.discount_code, 'NO_DISCOUNT') AS discount_code,
       COUNT(*) AS bookings_cnt,
       SUM(v.discount_amount) AS discount_given,
       ROUND(100.0 * SUM(v.discount_amount) / SUM(v.gross_amount), 1) AS avg_discount_pct,
       ROUND(AVG(v.net_amount), 0) AS avg_net_booking
FROM v_booking_financials v
JOIN bookings b ON b.booking_id = v.booking_id
LEFT JOIN discounts d ON d.discount_id = b.discount_id
WHERE v.booking_status <> 'cancelled'
GROUP BY COALESCE(d.discount_code, 'NO_DISCOUNT')
ORDER BY bookings_cnt DESC, discount_code;
```

Жолдар саны: 13

| discount_code | bookings_cnt | discount_given | avg_discount_pct | avg_net_booking |
|---|---|---|---|---|
| NO_DISCOUNT | 163 | 0 | 0 | 1378726 |
| LOYAL2 | 50 | 2138384 | 4 | 1026424 |
| FIX20K | 45 | 900000 | 1.4 | 1390187 |
| EARLY60 | 20 | 1529010 | 7 | 1015700 |
| PARTNER15K | 14 | 210000 | 1.6 | 933714 |
| SUMMER26 | 6 | 881840 | 8 | 1690193 |
| SUMMER25 | 4 | 413616 | 8 | 1189146 |
| BLACKFRI25 | 3 | 403720 | 10 | 1211160 |
| FAMILY4 | 3 | 301160 | 5 | 1907347 |
| NEWYEAR25 | 3 | 418390 | 7 | 1852870 |
| NAURYZ25 | 2 | 145560 | 6 | 1140220 |
| NAURYZ26 | 2 | 193410 | 6 | 1515045 |
| CORP10 | 1 | 82100 | 10 | 738900 |

## Q6.9. Виза режимі, сақтандыру қамтуы және визадан бас тарту

```sql
SELECT c.entry_regime,
       COUNT(*) AS bookings_cnt,
       COUNT(i.insurance_id) AS insured_cnt,
       ROUND(100.0 * COUNT(i.insurance_id) / COUNT(*), 1) AS insured_pct,
       SUM(CASE WHEN b.cancellation_reason = 'visa_refused' THEN 1 ELSE 0 END) AS visa_refused_cnt
FROM bookings b
JOIN tours t         ON t.tour_id = b.tour_id
JOIN tour_packages p ON p.package_id = t.package_id
JOIN destinations d  ON d.destination_id = p.destination_id
JOIN countries c     ON c.country_id = d.country_id
LEFT JOIN insurance i ON i.booking_id = b.booking_id
GROUP BY c.entry_regime
ORDER BY bookings_cnt DESC;
```

Жолдар саны: 4

| entry_regime | bookings_cnt | insured_cnt | insured_pct | visa_refused_cnt |
|---|---|---|---|---|
| visa_free | 243 | 81 | 33.3 | 0 |
| visa_required | 47 | 43 | 91.5 | 4 |
| visa_on_arrival | 42 | 14 | 33.3 | 0 |
| domestic | 19 | 0 | 0 | 0 |

## Q6.10. Клиент құндылығы (CLV): шығынға қарай квартильдер бойынша түсім үлесі

```sql
WITH spend AS (
    SELECT client_id, COUNT(*) AS trips, SUM(net_amount) AS spent
    FROM v_booking_financials
    WHERE booking_status IN ('completed', 'confirmed')
    GROUP BY client_id
), q AS (
    SELECT client_id, trips, spent, NTILE(4) OVER (ORDER BY spent DESC) AS quartile
    FROM spend
)
SELECT quartile,
       COUNT(*) AS clients_cnt,
       ROUND(AVG(trips), 2) AS avg_trips,
       ROUND(AVG(spent), 0) AS avg_clv,
       SUM(spent) AS revenue,
       ROUND(100.0 * SUM(spent) / SUM(SUM(spent)) OVER (), 1) AS revenue_share_pct
FROM q
GROUP BY quartile
ORDER BY quartile;
```

Жолдар саны: 4

| quartile | clients_cnt | avg_trips | avg_clv | revenue | revenue_share_pct |
|---|---|---|---|---|---|
| 1 | 43 | 2.72 | 4504939 | 193712356 | 48.5 |
| 2 | 43 | 2.05 | 2505843 | 107751260 | 27 |
| 3 | 43 | 1.23 | 1439212 | 61886104 | 15.5 |
| 4 | 42 | 1.21 | 862097 | 36208090 | 9.1 |

## Q6.11. Төленбеген қалдық: расталған және күтудегі брондаулар бойынша ең үлкен берешектер

```sql
SELECT v.booking_id, v.client_id, t.departure_date, v.net_amount,
       COALESCE(SUM(CASE WHEN py.payment_status = 'completed' AND py.payment_type <> 'refund' THEN py.amount END), 0) AS paid_amount,
       v.net_amount - COALESCE(SUM(CASE WHEN py.payment_status = 'completed' AND py.payment_type <> 'refund' THEN py.amount END), 0) AS outstanding
FROM v_booking_financials v
JOIN tours t ON t.tour_id = v.tour_id
LEFT JOIN payments py ON py.booking_id = v.booking_id
WHERE v.booking_status IN ('confirmed', 'pending')
GROUP BY v.booking_id, v.client_id, t.departure_date, v.net_amount
HAVING v.net_amount - COALESCE(SUM(CASE WHEN py.payment_status = 'completed' AND py.payment_type <> 'refund' THEN py.amount END), 0) > 0
ORDER BY outstanding DESC, v.booking_id
LIMIT 10;
```

Жолдар саны: 10

| booking_id | client_id | departure_date | net_amount | paid_amount | outstanding |
|---|---|---|---|---|---|
| 343 | 85 | 2027-01-03 | 2047500 | 0 | 2047500 |
| 350 | 243 | 2026-12-22 | 1184000 | 0 | 1184000 |
| 338 | 145 | 2026-12-04 | 1168000 | 0 | 1168000 |
| 329 | 64 | 2026-12-04 | 1606000 | 481800 | 1124200 |
| 336 | 199 | 2027-01-03 | 1092000 | 0 | 1092000 |
| 349 | 245 | 2027-01-03 | 1092000 | 0 | 1092000 |
| 340 | 168 | 2027-01-03 | 1072000 | 0 | 1072000 |
| 345 | 24 | 2027-01-14 | 1243500 | 373000 | 870500 |
| 304 | 190 | 2026-12-22 | 1184000 | 355200 | 828800 |
| 322 | 236 | 2026-12-22 | 1184000 | 355200 | 828800 |

## Q6.12. Айлық таза ақша ағыны және жинақталған сома (қайтарымдар шегеріліп)

```sql
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS pay_month,
       SUM(CASE WHEN payment_type = 'refund' THEN -amount ELSE amount END) AS net_cash,
       SUM(SUM(CASE WHEN payment_type = 'refund' THEN -amount ELSE amount END))
           OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM')) AS cumulative_cash
FROM payments
WHERE payment_status = 'completed'
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY pay_month;
```

Жолдар саны: 25

| pay_month | net_cash | cumulative_cash |
|---|---|---|
| 2024-11 | 4163100 | 4163100 |
| 2024-12 | 7586800 | 11749900 |
| 2025-01 | 28189140 | 39939040 |
| 2025-02 | 11544580 | 51483620 |
| 2025-03 | 13712940 | 65196560 |
| 2025-04 | 21173400 | 86369960 |
| 2025-05 | 14962600 | 101332560 |
| 2025-06 | 22482025 | 123814585 |
| 2025-07 | 24952640 | 148767225 |
| 2025-08 | 15327680 | 164094905 |
| 2025-09 | 13884000 | 177978905 |
| 2025-10 | 5044580 | 183023485 |
| 2025-11 | 18699890 | 201723375 |
| 2025-12 | 21719470 | 223442845 |
| 2026-01 | 11237760 | 234680605 |

## Q6.13. Авиакомпаниялардың уақытылылығы: кешігу үлесі және орташа кешігу

```sql
SELECT a.airline_name,
       COUNT(*) AS flights_cnt,
       ROUND(AVG(f.delay_minutes), 1) AS avg_delay_min,
       ROUND(100.0 * SUM(CASE WHEN f.delay_minutes > 60 THEN 1 ELSE 0 END) / COUNT(*), 1) AS delayed_over_60_pct
FROM flights f
JOIN airlines a ON a.airline_id = f.airline_id
WHERE f.flight_status = 'completed'
GROUP BY a.airline_name
HAVING COUNT(*) >= 6
ORDER BY delayed_over_60_pct DESC, a.airline_name;
```

Жолдар саны: 5

| airline_name | flights_cnt | avg_delay_min | delayed_over_60_pct |
|---|---|---|---|
| Turkish Airlines | 11 | 57.9 | 27.3 |
| SCAT Airlines | 28 | 24.3 | 14.3 |
| EgyptAir | 8 | 8.9 | 12.5 |
| Emirates | 11 | 10.9 | 9.1 |
| Air Astana | 42 | 18.4 | 7.1 |
