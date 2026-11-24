-- =====================================================================
-- 04_joins.sql: INNER, LEFT, RIGHT JOIN және FULL OUTER JOIN (UNION арқылы)
-- Q4.1, Q4.2, Q4.7-Q4.11 үш және одан көп кестені біріктіреді.
-- =====================================================================

-- Q4.1 INNER JOIN (4 кесте): болашақ турлар, елі мен бағыты көрсетілген
SELECT t.tour_id, p.package_name, d.destination_name, c.country_name, t.departure_date, t.price_per_person
FROM tours t
INNER JOIN tour_packages p ON p.package_id = t.package_id
INNER JOIN destinations d  ON d.destination_id = p.destination_id
INNER JOIN countries c     ON c.country_id = d.country_id
WHERE t.departure_date > '2026-11-22' AND t.tour_status <> 'cancelled'
ORDER BY t.departure_date, t.tour_id;

-- Q4.2 INNER JOIN (4 кесте): соңғы 12 брондау: клиент, турпакет, ұшу күні
SELECT b.booking_id, b.booking_date, cl.first_name, cl.last_name, p.package_name, t.departure_date
FROM bookings b
INNER JOIN clients cl      ON cl.client_id = b.client_id
INNER JOIN tours t         ON t.tour_id = b.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
ORDER BY b.booking_date DESC, b.booking_id DESC
LIMIT 12;

-- Q4.3 LEFT JOIN: бірде-бір рет брондау жасамаған клиенттер
SELECT cl.client_id, cl.first_name, cl.last_name, cl.city, cl.registration_date
FROM clients cl
LEFT JOIN booking_participants bp ON bp.client_id = cl.client_id
WHERE bp.participant_id IS NULL
ORDER BY cl.registration_date, cl.client_id;

-- Q4.4 LEFT JOIN: брондауы жоқ немесе барлық брондауы бас тартылған турлар
SELECT t.tour_id, p.package_name, t.departure_date, t.tour_status,
       COUNT(b.booking_id) AS active_bookings
FROM tours t
INNER JOIN tour_packages p ON p.package_id = t.package_id
LEFT JOIN bookings b ON b.tour_id = t.tour_id AND b.booking_status <> 'cancelled'
GROUP BY t.tour_id, p.package_name, t.departure_date, t.tour_status
HAVING COUNT(b.booking_id) = 0
ORDER BY t.departure_date;

-- Q4.5 RIGHT JOIN: ешқандай турпакетке кірмеген қонақүйлер
SELECT h.hotel_id, h.hotel_name, h.star_rating
FROM package_hotels ph
RIGHT JOIN hotels h ON h.hotel_id = ph.hotel_id
WHERE ph.package_id IS NULL
ORDER BY h.hotel_name;

-- Q4.6 FULL OUTER JOIN (LEFT JOIN UNION RIGHT JOIN): бағыттар мен турпакеттердің сәйкестігі
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

-- Q4.7 INNER JOIN (6 кесте): ел бойынша түскен түсім (қайтарымдар шегеріліп)
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

-- Q4.8 INNER JOIN (4 кесте): гидтердің жүктемесі (тур саны мен жұмыс күндері)
SELECT g.full_name, tg.assignment_role, COUNT(*) AS tours_cnt, SUM(p.duration_days) AS work_days
FROM guides g
INNER JOIN tour_guides tg  ON tg.guide_id = g.guide_id
INNER JOIN tours t         ON t.tour_id = tg.tour_id
INNER JOIN tour_packages p ON p.package_id = t.package_id
WHERE t.tour_status = 'completed'
GROUP BY g.full_name, tg.assignment_role
ORDER BY work_days DESC, g.full_name
LIMIT 10;

-- Q4.9 Өзіне-өзі қосу (бір кесте екі рет): ең жиі ұшатын маршруттар
SELECT o.destination_name AS origin_city, a.destination_name AS arrival_city, COUNT(*) AS flights_cnt
FROM flights f
INNER JOIN destinations o ON o.destination_id = f.origin_destination_id
INNER JOIN destinations a ON a.destination_id = f.arrival_destination_id
WHERE f.flight_status <> 'cancelled'
GROUP BY o.destination_name, a.destination_name
ORDER BY flights_cnt DESC, origin_city, arrival_city
LIMIT 10;

-- Q4.10 INNER JOIN (5 кесте): визасы қабылданбаған жолаушылар елдер бойынша
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

-- Q4.11 INNER JOIN (4 кесте): турпакеттер бойынша пікірлердің орташа бағасы
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

-- Q4.12 PostgreSQL-дегі тікелей FULL OUTER JOIN (Q4.6 нәтижесімен салыстыру үшін)
SELECT d.destination_name, p.package_name
FROM destinations d
FULL OUTER JOIN tour_packages p ON p.destination_id = d.destination_id
WHERE p.package_id IS NULL OR d.destination_id IS NULL
ORDER BY d.destination_name;
