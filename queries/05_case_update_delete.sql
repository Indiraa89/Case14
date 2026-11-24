-- =====================================================================
-- 05_case_update_delete.sql: CASE WHEN, UPDATE, DELETE, ALTER TABLE, DROP TABLE
-- Q5.1-Q5.6 шартты логика (сегменттеу, статус, бонус).
-- Q5.7-Q5.17 деректер мен құрылымды басқару. Барлық өзгерістер бір транзакцияда
-- орындалып, соңында ROLLBACK арқылы қайтарылады, сондықтан негізгі деректер бұзылмайды.
-- Өзгерісті тұрақты ету үшін ең соңғы ROLLBACK жолын COMMIT-ке ауыстыру жеткілікті.
-- =====================================================================

-- Q5.1 CASE (сегменттеу): клиенттерді сапар саны мен жұмсаған сомасы бойынша сегменттеу
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

-- Q5.2 CASE (брондау мерзімі): ұшуға дейін қанша күн бұрын брондалған
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

-- Q5.3 CASE (статус): аяқталған турлардың маржасы бойынша жіктелуі
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

-- Q5.4 CASE (статус): рейстердің ұшу уақытына сәйкестігі және үлесі
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

-- Q5.5 CASE (маусымдық сегменттеу): ұшу маусымы бойынша жолаушылар мен түсім
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

-- Q5.6 CASE (бонус): топ жетекшілеріне пікір бағасына байланысты сыйақы есептеу
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

-- =====================================================================
-- Деректерді басқару (транзакция ішінде)
-- =====================================================================
BEGIN;

-- Q5.7 ALTER TABLE (1): клиенттерге адалдық ұпайлары бағанын қосу
ALTER TABLE clients ADD COLUMN loyalty_points INTEGER NOT NULL DEFAULT 0;

-- Q5.8 UPDATE (1): аяқталған әр сапар үшін 100 ұпай беру
UPDATE clients
SET loyalty_points = 100 * (SELECT COUNT(*) FROM bookings b
                            WHERE b.client_id = clients.client_id AND b.booking_status = 'completed');

-- Q5.9 Тексеру: ұпайы ең жоғары клиенттер
SELECT client_id, first_name, last_name, loyalty_points
FROM clients
WHERE loyalty_points > 0
ORDER BY loyalty_points DESC, client_id
LIMIT 5;

-- Q5.10 ALTER TABLE (2): турпакеттерге «ұсынылған» белгісін қосу
ALTER TABLE tour_packages ADD COLUMN is_featured BOOLEAN NOT NULL DEFAULT FALSE;

-- Q5.11 UPDATE (2): аяқталған брондаулар саны бойынша ең танымал 3 турпакетті белгілеу
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

-- Q5.12 Тексеру: ұсынылған турпакеттер
SELECT package_id, package_name, is_featured FROM tour_packages WHERE is_featured = TRUE ORDER BY package_id;

-- Q5.13 UPDATE (3): 15 желтоқсаннан кейін ұшатын, әлі сатылып жатқан жағалау және қалалық турлардың
--       бағасын 5% көтеру (мерекелік кезеңде сұраныс жоғары; бұрын жасалған брондардың бағасы өзгермейді)
UPDATE tours
SET price_per_person = ROUND(price_per_person * 1.05, 0)
WHERE tour_status IN ('scheduled', 'confirmed')
  AND departure_date >= '2026-12-15'
  AND package_id IN (SELECT package_id FROM tour_packages WHERE tour_type IN ('beach', 'city_break'));

-- Q5.14 UPDATE (4): 10 күннен астам бойы бірде-бір төлемі түспеген «pending» брондауларды жабу
UPDATE bookings
SET booking_status = 'cancelled', cancellation_date = '2026-11-22', cancellation_reason = 'payment_overdue'
WHERE booking_status = 'pending'
  AND booking_date <= '2026-11-12'
  AND NOT EXISTS (SELECT 1 FROM payments p
                  WHERE p.booking_id = bookings.booking_id AND p.payment_status = 'completed');

-- Q5.15 DELETE: сәтті қайталанған төлемі бар сәтсіз (failed) жазбаларды жою
DELETE FROM payments
WHERE payment_status = 'failed'
  AND EXISTS (SELECT 1 FROM payments p2
              WHERE p2.booking_id = payments.booking_id
                AND p2.payment_type = payments.payment_type
                AND p2.payment_status = 'completed');

-- Q5.16 Тексеру: қалған сәтсіз төлемдер саны
SELECT payment_status, COUNT(*) AS payments_cnt FROM payments GROUP BY payment_status ORDER BY payment_status;

-- Q5.17 Уақытша кесте жасау және оны DROP TABLE арқылы жою
CREATE TABLE tmp_cancelled_report AS
SELECT b.booking_id, b.cancellation_reason, v.participants_cnt, v.net_amount
FROM bookings b
JOIN v_booking_financials v ON v.booking_id = b.booking_id
WHERE b.booking_status = 'cancelled';

SELECT cancellation_reason, COUNT(*) AS bookings_cnt, SUM(net_amount) AS lost_amount
FROM tmp_cancelled_report
GROUP BY cancellation_reason
ORDER BY lost_amount DESC;

DROP TABLE tmp_cancelled_report;

-- Барлық өзгерістерді қайтару (деректер бастапқы күйіне оралады)
ROLLBACK;
