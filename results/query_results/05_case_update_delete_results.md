# 05_case_update_delete.sql: орындау нәтижелері

CASE, UPDATE, DELETE, ALTER, DROP. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q5.1. CASE (сегменттеу): клиенттерді сапар саны мен жұмсаған сомасы бойынша сегменттеу

```sql
WITH client_stats AS (
    SELECT client_id, COUNT(*) AS trips, SUM(net_amount) AS spent
    FROM v_booking_financials
    WHERE booking_status IN ('completed', 'confirmed')
    GROUP BY client_id
)
SELECT CASE WHEN trips >= 4 OR spent >= 3000000 THEN 'VIP'
            WHEN trips >= 2 THEN 'Loyal'
            ELSE 'New' END AS segment,
       COUNT(*) AS clients_cnt,
       ROUND(AVG(spent), 0) AS avg_spent,
       SUM(spent) AS total_spent
FROM client_stats
GROUP BY CASE WHEN trips >= 4 OR spent >= 3000000 THEN 'VIP'
              WHEN trips >= 2 THEN 'Loyal'
              ELSE 'New' END
ORDER BY total_spent DESC;
```

Жолдар саны: 3

| segment | clients_cnt | avg_spent | total_spent |
|---|---|---|---|
| VIP | 45 | 4407361 | 198331256 |
| Loyal | 53 | 2110983 | 111882090 |
| New | 73 | 1223897 | 89344464 |

## Q5.2. CASE (брондау мерзімі): ұшуға дейін қанша күн бұрын брондалған

```sql
WITH lead AS (
    SELECT b.booking_id, v.net_amount,
           CASE WHEN (t.departure_date - b.booking_date) >= 90 THEN '1) 90+ күн'
                WHEN (t.departure_date - b.booking_date) >= 45 THEN '2) 45-89 күн'
                WHEN (t.departure_date - b.booking_date) >= 15 THEN '3) 15-44 күн'
                ELSE '4) 15 күннен аз' END AS lead_group
    FROM bookings b
    JOIN tours t ON t.tour_id = b.tour_id
    JOIN v_booking_financials v ON v.booking_id = b.booking_id
    WHERE b.booking_status <> 'cancelled'
)
SELECT lead_group, COUNT(*) AS bookings_cnt, ROUND(AVG(net_amount), 0) AS avg_booking_value
FROM lead
GROUP BY lead_group
ORDER BY lead_group;
```

Жолдар саны: 4

| lead_group | bookings_cnt | avg_booking_value |
|---|---|---|
| 1) 90+ күн | 62 | 1268806 |
| 2) 45-89 күн | 149 | 1353742 |
| 3) 15-44 күн | 79 | 1188827 |
| 4) 15 күннен аз | 26 | 1291092 |

## Q5.3. CASE (статус): аяқталған турлардың маржасы бойынша жіктелуі

```sql
WITH m AS (
    SELECT tour_id, (price_per_person - net_cost_per_person) * 100.0 / price_per_person AS margin_pct
    FROM tours
    WHERE tour_status = 'completed'
)
SELECT CASE WHEN margin_pct < 10 THEN 'төмен (<10%)'
            WHEN margin_pct <= 18 THEN 'қалыпты (10-18%)'
            ELSE 'жоғары (>18%)' END AS margin_status,
       COUNT(*) AS tours_cnt,
       ROUND(AVG(margin_pct), 1) AS avg_margin_pct
FROM m
GROUP BY CASE WHEN margin_pct < 10 THEN 'төмен (<10%)'
              WHEN margin_pct <= 18 THEN 'қалыпты (10-18%)'
              ELSE 'жоғары (>18%)' END
ORDER BY avg_margin_pct;
```

Жолдар саны: 3

| margin_status | tours_cnt | avg_margin_pct |
|---|---|---|
| төмен (<10%) | 4 | 6 |
| қалыпты (10-18%) | 48 | 15.2 |
| жоғары (>18%) | 11 | 19.2 |

## Q5.4. CASE (статус): рейстердің ұшу уақытына сәйкестігі және үлесі

```sql
SELECT CASE WHEN delay_minutes <= 15 THEN 'уақытында (<=15 мин)'
            WHEN delay_minutes <= 60 THEN 'шағын кешігу (16-60 мин)'
            ELSE 'үлкен кешігу (>60 мин)' END AS punctuality,
       COUNT(*) AS flights_cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM flights
WHERE flight_status = 'completed'
GROUP BY CASE WHEN delay_minutes <= 15 THEN 'уақытында (<=15 мин)'
              WHEN delay_minutes <= 60 THEN 'шағын кешігу (16-60 мин)'
              ELSE 'үлкен кешігу (>60 мин)' END
ORDER BY flights_cnt DESC;
```

Жолдар саны: 3

| punctuality | flights_cnt | share_pct |
|---|---|---|
| уақытында (<=15 мин) | 86 | 66.7 |
| шағын кешігу (16-60 мин) | 27 | 20.9 |
| үлкен кешігу (>60 мин) | 16 | 12.4 |

## Q5.5. CASE (маусымдық сегменттеу): ұшу маусымы бойынша жолаушылар мен түсім

```sql
SELECT CASE WHEN EXTRACT(MONTH FROM t.departure_date) IN (12, 1, 2) THEN 'қыс'
            WHEN EXTRACT(MONTH FROM t.departure_date) IN (3, 4, 5) THEN 'көктем'
            WHEN EXTRACT(MONTH FROM t.departure_date) IN (6, 7, 8) THEN 'жаз'
            ELSE 'күз' END AS season,
       COUNT(DISTINCT t.tour_id) AS tours_cnt,
       SUM(v.participants_cnt) AS travelers,
       SUM(v.net_amount) AS revenue
FROM tours t
JOIN v_booking_financials v ON v.tour_id = t.tour_id
WHERE v.booking_status IN ('completed', 'confirmed')
GROUP BY CASE WHEN EXTRACT(MONTH FROM t.departure_date) IN (12, 1, 2) THEN 'қыс'
              WHEN EXTRACT(MONTH FROM t.departure_date) IN (3, 4, 5) THEN 'көктем'
              WHEN EXTRACT(MONTH FROM t.departure_date) IN (6, 7, 8) THEN 'жаз'
              ELSE 'күз' END
ORDER BY revenue DESC;
```

Жолдар саны: 4

| season | tours_cnt | travelers | revenue |
|---|---|---|---|
| қыс | 21 | 181 | 113619600 |
| жаз | 19 | 212 | 108489230 |
| көктем | 19 | 162 | 97301500 |
| күз | 14 | 132 | 80147480 |

## Q5.6. CASE (бонус): топ жетекшілеріне пікір бағасына байланысты сыйақы есептеу

```sql
WITH fees AS (
    SELECT tg.guide_id, COUNT(*) AS tours_cnt, SUM(tg.agreed_fee) AS fee_total
    FROM tour_guides tg
    JOIN tours t ON t.tour_id = tg.tour_id
    WHERE tg.assignment_role = 'lead' AND t.tour_status = 'completed'
    GROUP BY tg.guide_id
), ratings AS (
    SELECT tg.guide_id, COUNT(r.review_id) AS reviews_cnt, AVG(r.guide_rating) AS avg_rating
    FROM tour_guides tg
    JOIN bookings b ON b.tour_id = tg.tour_id
    JOIN reviews r  ON r.booking_id = b.booking_id
    WHERE tg.assignment_role = 'lead'
    GROUP BY tg.guide_id
)
SELECT g.full_name, f.tours_cnt, rt.reviews_cnt, ROUND(rt.avg_rating, 2) AS avg_guide_rating, f.fee_total,
       CASE WHEN rt.avg_rating >= 4.5 THEN ROUND(f.fee_total * 0.15, 0)
            WHEN rt.avg_rating >= 4.0 THEN ROUND(f.fee_total * 0.07, 0)
            ELSE 0 END AS bonus_amount
FROM fees f
JOIN ratings rt ON rt.guide_id = f.guide_id
JOIN guides g   ON g.guide_id = f.guide_id
ORDER BY rt.avg_rating DESC, g.full_name;
```

Жолдар саны: 8

| full_name | tours_cnt | reviews_cnt | avg_guide_rating | fee_total | bonus_amount |
|---|---|---|---|---|---|
| Yerzhan Tolegenov | 1 | 2 | 4.5 | 140000 | 21000 |
| Aliya Nurmagambetova | 9 | 19 | 4.32 | 2356000 | 164920 |
| Marat Zhaksybekov | 18 | 39 | 4.21 | 3960000 | 277200 |
| Sergey Lim | 9 | 10 | 4.2 | 1980000 | 138600 |
| Aidos Bekmuratov | 9 | 19 | 3.95 | 2345000 | 0 |
| Dinara Kuandykova | 11 | 22 | 3.77 | 3010000 | 0 |
| Anton Belov | 3 | 2 | 3.5 | 665000 | 0 |
| Madina Sultanova | 3 | 1 | 3 | 576000 | 0 |

## Қосымша. BEGIN;

```sql
BEGIN;
```

Өзгерген жолдар саны: DDL/транзакция командасы

## Q5.7. ALTER TABLE (1): клиенттерге адалдық ұпайлары бағанын қосу

```sql
ALTER TABLE clients ADD COLUMN loyalty_points INTEGER NOT NULL DEFAULT 0;
```

Өзгерген жолдар саны: DDL/транзакция командасы

## Q5.8. UPDATE (1): аяқталған әр сапар үшін 100 ұпай беру

```sql
UPDATE clients
SET loyalty_points = 100 * (SELECT COUNT(*) FROM bookings b
                            WHERE b.client_id = clients.client_id AND b.booking_status = 'completed');
```

Өзгерген жолдар саны: 284

## Q5.9. Тексеру: ұпайы ең жоғары клиенттер

```sql
SELECT client_id, first_name, last_name, loyalty_points
FROM clients
WHERE loyalty_points > 0
ORDER BY loyalty_points DESC, client_id
LIMIT 5;
```

Жолдар саны: 5

| client_id | first_name | last_name | loyalty_points |
|---|---|---|---|
| 231 | Andrey | Morozov | 500 |
| 25 | Zarina | Petrova | 400 |
| 256 | Raushan | Ospanova | 400 |
| 258 | Daulet | Zhumabekov | 400 |
| 261 | Natalya | Rakhimova | 400 |

## Q5.10. ALTER TABLE (2): турпакеттерге «ұсынылған» белгісін қосу

```sql
ALTER TABLE tour_packages ADD COLUMN is_featured BOOLEAN NOT NULL DEFAULT FALSE;
```

Өзгерген жолдар саны: DDL/транзакция командасы

## Q5.11. UPDATE (2): аяқталған брондаулар саны бойынша ең танымал 3 турпакетті белгілеу

```sql
UPDATE tour_packages
SET is_featured = TRUE
WHERE package_id IN (
    SELECT t.package_id
    FROM tours t JOIN bookings b ON b.tour_id = t.tour_id
    WHERE b.booking_status = 'completed'
    GROUP BY t.package_id
    ORDER BY COUNT(*) DESC, t.package_id
    LIMIT 3
);
```

Өзгерген жолдар саны: 3

## Q5.12. Тексеру: ұсынылған турпакеттер

```sql
SELECT package_id, package_name, is_featured FROM tour_packages WHERE is_featured = TRUE ORDER BY package_id;
```

Жолдар саны: 3

| package_id | package_name | is_featured |
|---|---|---|
| 1 | Antalya Family All-Inclusive | 1 |
| 4 | Dubai Winter Escape | 1 |
| 6 | Hurghada Red Sea All-Inclusive | 1 |

## Q5.13. UPDATE (3): 15 желтоқсаннан кейін ұшатын, әлі сатылып жатқан жағалау және қалалық турлардың

```sql
UPDATE tours
SET price_per_person = ROUND(price_per_person * 1.05, 0)
WHERE tour_status IN ('scheduled', 'confirmed')
  AND departure_date >= '2026-12-15'
  AND package_id IN (SELECT package_id FROM tour_packages WHERE tour_type IN ('beach', 'city_break'));
```

Өзгерген жолдар саны: 4

## Q5.14. UPDATE (4): 10 күннен астам бойы бірде-бір төлемі түспеген «pending» брондауларды жабу

```sql
UPDATE bookings
SET booking_status = 'cancelled', cancellation_date = '2026-11-22', cancellation_reason = 'payment_overdue'
WHERE booking_status = 'pending'
  AND booking_date <= '2026-11-12'
  AND NOT EXISTS (SELECT 1 FROM payments p
                  WHERE p.booking_id = bookings.booking_id AND p.payment_status = 'completed');
```

Өзгерген жолдар саны: 4

## Q5.15. DELETE: сәтті қайталанған төлемі бар сәтсіз (failed) жазбаларды жою

```sql
DELETE FROM payments
WHERE payment_status = 'failed'
  AND EXISTS (SELECT 1 FROM payments p2
              WHERE p2.booking_id = payments.booking_id
                AND p2.payment_type = payments.payment_type
                AND p2.payment_status = 'completed');
```

Өзгерген жолдар саны: 14

## Q5.16. Тексеру: қалған сәтсіз төлемдер саны

```sql
SELECT payment_status, COUNT(*) AS payments_cnt FROM payments GROUP BY payment_status ORDER BY payment_status;
```

Жолдар саны: 2

| payment_status | payments_cnt |
|---|---|
| completed | 606 |
| pending | 8 |

## Q5.17. Уақытша кесте жасау және оны DROP TABLE арқылы жою

```sql
CREATE TABLE tmp_cancelled_report AS
SELECT b.booking_id, b.cancellation_reason, v.participants_cnt, v.net_amount
FROM bookings b
JOIN v_booking_financials v ON v.booking_id = b.booking_id
WHERE b.booking_status = 'cancelled';
```

Өзгерген жолдар саны: DDL/транзакция командасы

## Қосымша. SELECT cancellation_reason, COUNT(*) AS bookings_cnt, SUM(net_amount) AS lost_amount

```sql
SELECT cancellation_reason, COUNT(*) AS bookings_cnt, SUM(net_amount) AS lost_amount
FROM tmp_cancelled_report
GROUP BY cancellation_reason
ORDER BY lost_amount DESC;
```

Жолдар саны: 6

| cancellation_reason | bookings_cnt | lost_amount |
|---|---|---|
| client_request | 16 | 17861360 |
| payment_overdue | 8 | 8859900 |
| tour_cancelled | 4 | 6452200 |
| illness | 4 | 6117860 |
| visa_refused | 4 | 6041040 |
| schedule_conflict | 3 | 4934000 |

## Қосымша. DROP TABLE tmp_cancelled_report;

```sql
DROP TABLE tmp_cancelled_report;
```

Өзгерген жолдар саны: DDL/транзакция командасы

## Қосымша. ROLLBACK;

```sql
ROLLBACK;
```

Өзгерген жолдар саны: DDL/транзакция командасы
