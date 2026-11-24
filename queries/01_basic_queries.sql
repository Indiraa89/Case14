-- =====================================================================
-- 01_basic_queries.sql: негізгі SELECT, DISTINCT, ORDER BY, LIMIT
-- Бизнес-сұрақтар турагенттіктің күнделікті жұмысына байланысты қойылған.
-- =====================================================================

-- Q1.1 Елдер тізімі: Қазақстан азаматтарына кіру режимі бойынша топталған
SELECT country_name, iso_code, entry_regime, insurance_mandatory
FROM countries
ORDER BY entry_regime, country_name;

-- Q1.2 Клиенттер тұратын қалалар (қайталанбайтын мәндер)
SELECT DISTINCT city
FROM clients
ORDER BY city;

-- Q1.3 Нетто тарифі ең жоғары 10 қонақүй
SELECT hotel_name, star_rating, board_type, price_per_night
FROM hotels
ORDER BY price_per_night DESC, hotel_name
LIMIT 10;

-- Q1.4 Каталогтағы ең арзан 8 турпакет
SELECT package_name, tour_type, duration_days, base_price
FROM tour_packages
ORDER BY base_price ASC, package_name
LIMIT 8;

-- Q1.5 Төлем әдістері мен төлем түрлерінің қолданылған үйлесімдері
SELECT DISTINCT payment_method, payment_type
FROM payments
ORDER BY payment_method, payment_type;
