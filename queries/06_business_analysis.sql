-- =====================================================================
-- 06_business_analysis.sql: басшылыққа арналған негізгі бизнес-есептер
-- Түсім = жеңілдіктен кейінгі соммасы (v_booking_financials.net_amount);
-- есептерде бас тартылған брондаулар қосылмайды, егер басқаша көрсетілмесе.
-- Өзіндік құн = tours.net_cost_per_person * жолаушылар саны.
-- =====================================================================

-- Q6.1 Ең сұранысқа ие елдер: брондау, жолаушы, түсім, үлес және орын
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

-- Q6.2 Ең сұранысқа ие бағыттар: жолаушы саны және бір жолаушыға орташа түсім
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

-- Q6.3 Рентабельді турпакеттер: аяқталған турлар бойынша түсім, шығын, пайда және маржа
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

-- Q6.4 Маусымдық белсенділік: ұшу айы бойынша жолаушылар мен түсім үлесі
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

-- Q6.5 Турлардың толу коэффициенті (load factor), аяқталған турлар
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

-- Q6.6 Бас тартулардың себептері, үлесі және жоғалған түсім
SELECT b.cancellation_reason,
       COUNT(*) AS cancelled_cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct,
       SUM(v.net_amount) AS booked_amount
FROM bookings b
JOIN v_booking_financials v ON v.booking_id = b.booking_id
WHERE b.booking_status = 'cancelled'
GROUP BY b.cancellation_reason
ORDER BY cancelled_cnt DESC, b.cancellation_reason;

-- Q6.7 Бас тарту деңгейі турпакет түрі бойынша
SELECT p.tour_type,
       COUNT(*) AS bookings_cnt,
       SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt,
       ROUND(100.0 * SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM bookings b
JOIN tours t         ON t.tour_id = b.tour_id
JOIN tour_packages p ON p.package_id = t.package_id
GROUP BY p.tour_type
ORDER BY cancel_rate_pct DESC, p.tour_type;

-- Q6.8 Жеңілдіктердің тиімділігі: қолданылу саны, берілген жеңілдік және орташа чек
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

-- Q6.9 Виза режимі, сақтандыру қамтуы және визадан бас тарту
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

-- Q6.10 Клиент құндылығы (CLV): шығынға қарай квартильдер бойынша түсім үлесі
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

-- Q6.11 Төленбеген қалдық: расталған және күтудегі брондаулар бойынша ең үлкен берешектер
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

-- Q6.12 Айлық таза ақша ағыны және жинақталған сома (қайтарымдар шегеріліп)
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS pay_month,
       SUM(CASE WHEN payment_type = 'refund' THEN -amount ELSE amount END) AS net_cash,
       SUM(SUM(CASE WHEN payment_type = 'refund' THEN -amount ELSE amount END))
           OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM')) AS cumulative_cash
FROM payments
WHERE payment_status = 'completed'
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY pay_month;

-- Q6.13 Авиакомпаниялардың уақытылылығы: кешігу үлесі және орташа кешігу
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
