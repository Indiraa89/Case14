-- =====================================================================
-- 03_aggregation.sql: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
-- Q3.1-Q3.6 агрегаттау, Q3.7-Q3.12 GROUP BY, Q3.13-Q3.19 HAVING (WHERE-пен бірге)
-- =====================================================================

-- ---------------- Агрегаттық функциялар ----------------

-- Q3.1 COUNT: брондаулар мен брондау жасаған бірегей клиенттер саны
SELECT COUNT(*) AS total_bookings,
       COUNT(DISTINCT client_id) AS booking_clients,
       COUNT(cancellation_date) AS cancelled_bookings
FROM bookings;

-- Q3.2 SUM: сәтті өткен түсімдердің жалпы сомасы (қайтарымдарсыз)
SELECT SUM(amount) AS received_total
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund';

-- Q3.3 AVG: аяқталған турлардың бір адамға орташа бағасы және орташа өзіндік құны
SELECT ROUND(AVG(price_per_person), 0) AS avg_price,
       ROUND(AVG(net_cost_per_person), 0) AS avg_cost
FROM tours
WHERE tour_status = 'completed';

-- Q3.4 MIN және MAX: тур бағасының диапазоны мен сыйымдылығы
SELECT MIN(price_per_person) AS min_price, MAX(price_per_person) AS max_price,
       MIN(max_participants) AS min_capacity, MAX(max_participants) AS max_capacity
FROM tours;

-- Q3.5 AVG: пікірлердің орташа бағалары
SELECT ROUND(AVG(overall_rating), 2) AS overall,
       ROUND(AVG(hotel_rating), 2) AS hotel,
       ROUND(AVG(guide_rating), 2) AS guide,
       ROUND(AVG(service_rating), 2) AS service,
       COUNT(*) AS reviews_cnt
FROM reviews;

-- Q3.6 SUM және MAX: бұғатталған авиаорындар және ең ұзақ кешігу
SELECT SUM(seats_blocked) AS blocked_seats, MAX(delay_minutes) AS max_delay
FROM flights
WHERE flight_status <> 'cancelled';

-- ---------------- GROUP BY ----------------

-- Q3.7 Брондаулар саны статус бойынша
SELECT booking_status, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY booking_status
ORDER BY bookings_cnt DESC;

-- Q3.8 Сату арналары бойынша брондаулар саны
SELECT booking_channel, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY booking_channel
ORDER BY bookings_cnt DESC, booking_channel;

-- Q3.9 Жолаушы түрі бойынша саны және жиынтық баға
SELECT traveler_type, COUNT(*) AS travelers, SUM(unit_price) AS gross_sum, ROUND(AVG(unit_price), 0) AS avg_price
FROM booking_participants
GROUP BY traveler_type
ORDER BY travelers DESC;

-- Q3.10 Төлем әдісі бойынша сәтті түсімдер
SELECT payment_method, COUNT(*) AS payments_cnt, SUM(amount) AS total_amount
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund'
GROUP BY payment_method
ORDER BY total_amount DESC;

-- Q3.11 Авиакомпания бойынша аяқталған рейстердің орташа кешігуі
SELECT airline_id, COUNT(*) AS flights_cnt, ROUND(AVG(delay_minutes), 1) AS avg_delay
FROM flights
WHERE flight_status = 'completed'
GROUP BY airline_id
ORDER BY avg_delay DESC, airline_id;

-- Q3.12 Баға (жұлдыз) бойынша қонақүйлер саны мен орташа тариф
SELECT star_rating, COUNT(*) AS hotels_cnt, ROUND(AVG(price_per_night), 0) AS avg_rate
FROM hotels
GROUP BY star_rating
ORDER BY star_rating DESC;

-- ---------------- HAVING (WHERE пен бірге) ----------------

-- Q3.13 Бас тартылмаған 3 және одан көп брондауы бар клиенттер
SELECT client_id, COUNT(*) AS bookings_cnt
FROM bookings
WHERE booking_status <> 'cancelled'
GROUP BY client_id
HAVING COUNT(*) >= 3
ORDER BY bookings_cnt DESC, client_id;

-- Q3.14 Орташа кешігуі 20 минуттан асатын авиакомпаниялар (аяқталған рейстер ғана)
SELECT airline_id, COUNT(*) AS flights_cnt, ROUND(AVG(delay_minutes), 1) AS avg_delay
FROM flights
WHERE flight_status = 'completed'
GROUP BY airline_id
HAVING AVG(delay_minutes) > 20
ORDER BY avg_delay DESC;

-- Q3.15 Бір брондау бойынша түскен сома 2 млн теңгеден асатын брондаулар
SELECT booking_id, COUNT(*) AS payments_cnt, SUM(amount) AS paid_total
FROM payments
WHERE payment_status = 'completed' AND payment_type <> 'refund'
GROUP BY booking_id
HAVING SUM(amount) > 2000000
ORDER BY paid_total DESC, booking_id
LIMIT 15;

-- Q3.16 4-5 жұлдызды қонақүйлері бар, орташа тарифі 50 мың теңгеден жоғары бағыттар
SELECT destination_id, COUNT(*) AS hotels_cnt, ROUND(AVG(price_per_night), 0) AS avg_rate
FROM hotels
WHERE star_rating >= 4
GROUP BY destination_id
HAVING AVG(price_per_night) > 50000
ORDER BY avg_rate DESC;

-- Q3.17 Кемінде 8 рет қолданылған жеңілдіктер
SELECT discount_id, COUNT(*) AS used_cnt
FROM bookings
WHERE discount_id IS NOT NULL
GROUP BY discount_id
HAVING COUNT(*) >= 8
ORDER BY used_cnt DESC, discount_id;

-- Q3.18 Кемінде 3 пікірі бар және орташа бағасы 4.3-тен төмен турлар (2025 жылдан бастап)
SELECT b.tour_id, COUNT(*) AS reviews_cnt, ROUND(AVG(r.overall_rating), 2) AS avg_rating
FROM reviews r
JOIN bookings b ON b.booking_id = r.booking_id
WHERE r.review_date >= '2025-01-01'
GROUP BY b.tour_id
HAVING COUNT(*) >= 3 AND AVG(r.overall_rating) < 4.3
ORDER BY avg_rating, b.tour_id;

-- Q3.19 WHERE мен HAVING айырмасы: бір шарт екі жерде
--       (а) WHERE жолдарды топтауға дейін сүзеді: тек 'completed' брондаулар санатындағы клиенттер
SELECT client_id, COUNT(*) AS completed_cnt
FROM bookings
WHERE booking_status = 'completed'
GROUP BY client_id
HAVING COUNT(*) >= 2
ORDER BY completed_cnt DESC, client_id
LIMIT 10;

-- Q3.20 (ә) HAVING топтарды есептегеннен кейін сүзеді: барлық брондау саны 4+ болған клиенттер
SELECT client_id, COUNT(*) AS all_bookings,
       SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt
FROM bookings
GROUP BY client_id
HAVING COUNT(*) >= 4
ORDER BY all_bookings DESC, client_id
LIMIT 10;

-- Q3.21 WHERE мен HAVING айырмасы: Q3.13-тің WHERE шартынсыз нұсқасы (бас тартылған брондаулар да саналады)
SELECT client_id, COUNT(*) AS bookings_cnt
FROM bookings
GROUP BY client_id
HAVING COUNT(*) >= 3
ORDER BY bookings_cnt DESC, client_id;
