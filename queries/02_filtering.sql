-- =====================================================================
-- 02_filtering.sql: WHERE, AND, OR, NOT, BETWEEN, IN, LIKE, IS NULL
-- Q2.5 пен Q2.6 көп шартты сүзу сұраныстары.
-- Бақылау күні (TODAY) = 2026-11-22.
-- =====================================================================

-- Q2.1 AND: «барлығы қосылған» тамақтануы бар 5 жұлдызды қонақүйлер
SELECT hotel_name, board_type, price_per_night
FROM hotels
WHERE star_rating = 5 AND board_type IN ('AI', 'UAI')
ORDER BY price_per_night DESC, hotel_name;

-- Q2.2 BETWEEN: 2026 жылғы жазғы мезгілде ұшатын турлар
SELECT tour_id, package_id, departure_date, return_date, price_per_person, tour_status
FROM tours
WHERE departure_date BETWEEN '2026-06-01' AND '2026-08-31'
ORDER BY departure_date, tour_id;

-- Q2.3 IN: виза талап ететін немесе визаны келгенде беретін елдер
SELECT country_name, entry_regime, insurance_mandatory
FROM countries
WHERE entry_regime IN ('visa_required', 'visa_on_arrival')
ORDER BY country_name;

-- Q2.4 LIKE: аты «Ai» әріптерінен басталатын Астана клиенттері
SELECT client_id, first_name, last_name, city
FROM clients
WHERE first_name LIKE 'Ai%' AND city = 'Astana'
ORDER BY last_name, first_name;

-- Q2.5 Көп шартты сүзу (AND, OR, NOT): белсенді жағалау турлары 600 мың теңгеге дейін
--      немесе 6 күнге дейінгі қалалық турлар, Стамбулдан басқа
SELECT package_name, tour_type, duration_days, base_price
FROM tour_packages
WHERE is_active = TRUE
  AND ((tour_type = 'beach' AND base_price < 600000)
       OR (tour_type = 'city_break' AND duration_days <= 6))
  AND NOT (destination_id = 5)
ORDER BY base_price, package_name;

-- Q2.6 Көп шартты сүзу: 1-2 сағатқа дейін кешіккен экономклассты рейстер
SELECT flight_id, flight_number, departure_at, delay_minutes, cabin_class
FROM flights
WHERE flight_status = 'completed'
  AND cabin_class = 'economy'
  AND (delay_minutes BETWEEN 60 AND 120 OR delay_minutes > 240)
ORDER BY delay_minutes DESC, flight_id
LIMIT 15;

-- Q2.7 IS NULL: 2026 жылдың қыркүйегінен кейінгі жеңілдіксіз расталған брондаулар
SELECT booking_id, client_id, tour_id, booking_date, booking_channel
FROM bookings
WHERE discount_id IS NULL
  AND booking_status = 'confirmed'
  AND booking_date >= '2026-09-01'
ORDER BY booking_date, booking_id;

-- Q2.8 LIKE және NOT LIKE: атауында Resort бар, бірақ Spa жоқ қонақүйлер
SELECT hotel_name, star_rating, price_per_night
FROM hotels
WHERE hotel_name LIKE '%Resort%' AND hotel_name NOT LIKE '%Spa%'
ORDER BY hotel_name;

-- Q2.9 BETWEEN: паспорты алдағы 8 айда біткен белсенді клиенттер
SELECT client_id, first_name, last_name, passport_expiry
FROM clients
WHERE passport_expiry BETWEEN '2026-11-22' AND '2027-07-31'
  AND is_active = TRUE
ORDER BY passport_expiry, client_id
LIMIT 20;
